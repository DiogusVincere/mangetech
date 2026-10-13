import os
import csv
import base64
from io import BytesIO
from datetime import timedelta

from rest_framework.permissions import IsAdminUser

from PIL import Image, ImageDraw, ImageFont
import qrcode

from django.http import HttpResponse
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.db.models import Q, Count

from rest_framework import viewsets, filters, status
from rest_framework.decorators import api_view, action, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token

from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone



from .models import (
    Chamado,
    ChamadoStatusHistory,
    ChamadoStatusImage,
    ChamadoAnexo,
    Comentario,
    Ativo,
    AtivoHistorico
)
from .serializers import (
    ChamadoReadSerializer,
    ChamadoWriteSerializer,
    MudarStatusSerializer,
    ComentarioSerializer,
    CriarComentarioSerializer,
    AtivoSerializer,
    UserSerializer,
    UserRegistrationSerializer,
    UserLoginSerializer
)

from .filters import ChamadoFilter, AtivoFilter

from .models import TokenRecuperacaoSenha, VerificacaoEmail
from .email_service import VerificadorEmail, EnviadorEmail

# chamados/views.py

class QRCodeGenerator:
    """Gera QR Codes para ativos de forma profissional"""

    # Configurações
    QR_VERSION = 1
    QR_BOX_SIZE = 10
    QR_BORDER = 4
    QR_FILL_COLOR = "black"
    QR_BACK_COLOR = "white"

    @staticmethod
    def gerar_qr_codigo(dados: str, incluir_logo: bool = False) -> Image.Image:
        qr = qrcode.QRCode(
            version=QRCodeGenerator.QR_VERSION,
            error_correction=qrcode.constants.ERROR_CORRECT_H,
            box_size=QRCodeGenerator.QR_BOX_SIZE,
            border=QRCodeGenerator.QR_BORDER,
        )
        qr.add_data(dados)
        qr.make(fit=True)

        img = qr.make_image(
            fill_color=QRCodeGenerator.QR_FILL_COLOR,
            back_color=QRCodeGenerator.QR_BACK_COLOR,
        ).convert("RGB")
        return img

    @staticmethod
    def gerar_qr_com_label(dados: str, label: str = None, tamanho_label: int = 20) -> Image.Image:
        qr_img = QRCodeGenerator.gerar_qr_codigo(dados)

        if not label:
            return qr_img

        # espaço para label
        label_height = tamanho_label + 20
        nova_img = Image.new('RGB', (qr_img.width, qr_img.height + label_height), 'white')
        nova_img.paste(qr_img, (0, 0))

        draw = ImageDraw.Draw(nova_img)
        
        # USAR FONT PADRÃO DO PILLOW
        try:
            font = ImageFont.load_default()
        except:
            font = None

        # Quebra de linhas simples se houver \n
        lines = label.splitlines() if isinstance(label, str) else [str(label)]

        # calcular posição vertical inicial
        current_y = qr_img.height + 5
        for line in lines:
            # NOVO MÉTODO PARA PILLOW 10+
            if font:
                # Usar textbbox para calcular tamanho do texto
                bbox = draw.textbbox((0, 0), line, font=font)
                text_width = bbox[2] - bbox[0]
                text_height = bbox[3] - bbox[1]
            else:
                # Fallback se não houver fonte
                text_width = len(line) * 8
                text_height = 12
            
            x_pos = (nova_img.width - text_width) / 2
            draw.text((x_pos, current_y), line, fill='black', font=font)
            current_y += text_height + 2

        return nova_img

    @staticmethod
    def gerar_qr_base64(dados: str, label: str = None, com_label: bool = False) -> str:
        if com_label and label:
            img = QRCodeGenerator.gerar_qr_com_label(dados, label)
        else:
            img = QRCodeGenerator.gerar_qr_codigo(dados)

        buffer = BytesIO()
        img.save(buffer, format='PNG')
        buffer.seek(0)
        return base64.b64encode(buffer.getvalue()).decode()

    @staticmethod
    def salvar_qr_arquivo(dados: str, caminho: str, label: str = None, com_label: bool = False) -> bool:
        try:
            if com_label and label:
                img = QRCodeGenerator.gerar_qr_com_label(dados, label)
            else:
                img = QRCodeGenerator.gerar_qr_codigo(dados)

            os.makedirs(os.path.dirname(caminho), exist_ok=True)
            img.save(caminho)
            return True
        except Exception as e:
            print(f"Erro ao salvar QR code: {e}")
            return False


class QRCodeSerializer:
    """Serializer utilitário para QR codes"""

    @staticmethod
    def get_qr_base64(ativo_codigo: str) -> str:
        return QRCodeGenerator.gerar_qr_base64(ativo_codigo)

    @staticmethod
    def get_qr_com_label(ativo_codigo: str, ativo_nome: str = None) -> str:
        label = f"{ativo_codigo}\n{ativo_nome}" if ativo_nome else ativo_codigo
        return QRCodeGenerator.gerar_qr_base64(ativo_codigo, label=label, com_label=True)


# =========================
# AUTENTICAÇÃO
# =========================
@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    """Cadastro de novo usuário"""
    serializer = UserRegistrationSerializer(data=request.data)

    if serializer.is_valid():
        user = serializer.save()
        token, _ = Token.objects.get_or_create(user=user)

        return Response({
            'success': True,
            'message': 'Usuário criado com sucesso!',
            'user': UserSerializer(user).data,
            'token': token.key
        }, status=status.HTTP_201_CREATED)

    return Response({
        'success': False,
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    """Login de usuário"""
    email = request.data.get('email', '').strip().lower()
    senha = request.data.get('senha', '').strip()

    # Validações básicas
    if not email or not senha:
        return Response({
            'success': False,
            'message': 'Email e senha são obrigatórios'
        }, status=status.HTTP_400_BAD_REQUEST)

    try:
        # Buscar usuário pelo email
        user = User.objects.get(email=email)
        
        # Verificar se o usuário está ativo
        if not user.is_active:
            return Response({
                'success': False,
                'message': 'Sua conta está inativa. Entre em contato com o administrador.'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # Autenticar com username (Django usa username internamente)
        authenticated_user = authenticate(username=user.username, password=senha)
        
        if authenticated_user:
            # Criar ou pegar token
            token, _ = Token.objects.get_or_create(user=authenticated_user)
            
            return Response({
                'success': True,
                'message': 'Login realizado com sucesso!',
                'user': UserSerializer(authenticated_user).data,
                'token': token.key
            }, status=status.HTTP_200_OK)
        else:
            # Senha incorreta
            return Response({
                'success': False,
                'message': 'Email ou senha incorretos'
            }, status=status.HTTP_401_UNAUTHORIZED)

    except User.DoesNotExist:
        # Email não existe
        return Response({
            'success': False,
            'message': 'Email ou senha incorretos'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Erro no servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def logout_user(request):
    """Logout de usuário"""
    if request.user.is_authenticated:
        Token.objects.filter(user=request.user).delete()
        return Response({
            'success': True,
            'message': 'Logout realizado com sucesso'
        })

    return Response({
        'success': False,
        'message': 'Usuário não autenticado'
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def recuperar_senha(request):
    """Solicitar recuperação de senha"""
    email = request.data.get('email')

    if not email:
        return Response({
            'success': False,
            'message': 'Email é obrigatório'
        }, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(email=email)
        # Aqui você implementaria o envio de email real
        # Por enquanto, apenas simula

        return Response({
            'success': True,
            'message': 'Instruções enviadas para o email'
        })

    except User.DoesNotExist:
        # Por segurança, não revela se o email existe ou não
        return Response({
            'success': True,
            'message': 'Se o email existir, instruções serão enviadas'
        })

# =========================
# RECUPERAÇÃO DE SENHA (NOVO)
# =========================



@api_view(['POST'])
@permission_classes([AllowAny])
def solicitar_recuperacao_senha(request):
    email = request.data.get('email', '').strip().lower()

    if not email:
        return Response({'success': False, 'message': 'Email é obrigatório'}, status=status.HTTP_400_BAD_REQUEST)

    if '@' not in email or '.' not in email:
        return Response({'success': False, 'message': 'Email inválido'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        usuario = User.objects.get(email=email)

        token_obj = TokenRecuperacaoSenha.criar_para_usuario(usuario, email)

        email_enviado = EnviadorEmail.enviar_token_recuperacao(usuario, token_obj)

        if not email_enviado:
            return Response({
                'success': False,
                'message': 'Erro ao enviar email. Tente novamente mais tarde.'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        return Response({
            'success': True,
            'message': f'Código enviado para {email}',
            'email_mascarado': _mascarar_email(email),
            'tempo_expiracao': 15
        }, status=status.HTTP_200_OK)

    except User.DoesNotExist:
        return Response({
            'success': True,
            'message': f'Se o email existir, você receberá um código',
            'email_mascarado': _mascarar_email(email),
            'tempo_expiracao': 15
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'success': False, 'message': f'Erro: {str(e)}'},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([AllowAny])
def verificar_token_recuperacao(request):
    email = request.data.get('email', '').strip().lower()
    token = request.data.get('token', '').strip()

    if not email or not token:
        return Response({'success': False, 'message': 'Email e token são obrigatórios'},
                        status=status.HTTP_400_BAD_REQUEST)

    try:
        usuario = User.objects.get(email=email)
        token_obj = TokenRecuperacaoSenha.objects.get(user=usuario)

        if token_obj.verificar_token(token):
            return Response({
                'success': True,
                'message': 'Token verificado com sucesso',
                'usuario_id': usuario.id
            }, status=status.HTTP_200_OK)

        tentativas_restantes = token_obj.max_tentativas - token_obj.tentativas

        if tentativas_restantes <= 0:
            return Response({
                'success': False,
                'message': 'Máximo de tentativas atingido. Solicite um novo código.',
                'token_expirado': True
            }, status=status.HTTP_400_BAD_REQUEST)

        return Response({
            'success': False,
            'message': f'Token inválido. {tentativas_restantes} tentativa(s) restante(s)',
            'tentativas_restantes': tentativas_restantes
        }, status=status.HTTP_400_BAD_REQUEST)

    except (User.DoesNotExist, TokenRecuperacaoSenha.DoesNotExist):
        return Response({
            'success': False,
            'message': 'Email ou token inválido'
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def resetar_senha(request):
    email = request.data.get('email', '').strip().lower()
    token = request.data.get('token', '').strip()
    nova_senha = request.data.get('nova_senha', '').strip()
    confirmar_senha = request.data.get('confirmar_senha', '').strip()

    if not all([email, token, nova_senha, confirmar_senha]):
        return Response({'success': False, 'message': 'Todos os campos são obrigatórios'},
                        status=status.HTTP_400_BAD_REQUEST)

    if nova_senha != confirmar_senha:
        return Response({'success': False, 'message': 'Senhas não conferem'},
                        status=status.HTTP_400_BAD_REQUEST)

    if len(nova_senha) < 6:
        return Response({'success': False, 'message': 'Senha deve ter no mínimo 6 caracteres'},
                        status=status.HTTP_400_BAD_REQUEST)

    try:
        usuario = User.objects.get(email=email)
        token_obj = TokenRecuperacaoSenha.objects.get(user=usuario)

        if not token_obj.verificar_token(token):
            return Response({'success': False, 'message': 'Token inválido ou expirado'},
                            status=status.HTTP_400_BAD_REQUEST)

        usuario.set_password(nova_senha)
        usuario.save()

        EnviadorEmail.enviar_confirmacao_resetar_senha(usuario, nova_senha)

        return Response({'success': True, 'message': 'Senha resetada com sucesso. Faça login com sua nova senha.'},
                        status=status.HTTP_200_OK)

    except (User.DoesNotExist, TokenRecuperacaoSenha.DoesNotExist):
        return Response({'success': False, 'message': 'Email ou token inválido'},
                        status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        return Response({'success': False, 'message': f'Erro: {str(e)}'},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([AllowAny])
def verificar_email_real(request):
    email = request.data.get('email', '').strip().lower()

    if not email:
        return Response({'success': False, 'message': 'Email é obrigatório'},
                        status=status.HTTP_400_BAD_REQUEST)

    try:
        verificacao = VerificacaoEmail.objects.get(email=email)

        if verificacao.status == 'VERIFICADO':
            return Response({
                'success': True,
                'email': email,
                'valido': True,
                'mensagem': 'Email já verificado anteriormente',
                'verificado': True
            })

        elif verificacao.status == 'REJEITADO':
            return Response({
                'success': False,
                'email': email,
                'valido': False,
                'mensagem': 'Email rejeitado anteriormente'
            }, status=status.HTTP_400_BAD_REQUEST)

    except VerificacaoEmail.DoesNotExist:
        resultado = VerificadorEmail.verificar_email_completo(email)

        verificacao = VerificacaoEmail.objects.create(
            email=email,
            sintaxe_ok=resultado['sintaxe_ok'],
            dominio_ok=resultado['dominio_ok'],
            email_real=resultado['email_real'],
            status='VERIFICADO' if resultado['valido'] else 'REJEITADO'
        )

        if not resultado['valido']:
            return Response({
                'success': False,
                'email': email,
                'valido': False,
                'mensagem': resultado['mensagem'],
                'detalhes': resultado
            }, status=status.HTTP_400_BAD_REQUEST)

    return Response({
        'success': True,
        'email': email,
        'valido': True,
        'mensagem': 'Email válido e real',
        'verificado': True
    })


def _mascarar_email(email: str) -> str:
    partes = email.split('@')
    nome = partes[0]
    dominio = partes[1]

    if len(nome) > 2:
        nome_mascarado = nome[0] + '*' * (len(nome) - 2) + nome[-1]
    else:
        nome_mascarado = '*' * len(nome)

    return f"{nome_mascarado}@{dominio}"


# =========================
# CHAMADOS
# =========================
class ChamadoViewSet(viewsets.ModelViewSet):
    """
    ViewSet para Chamados com filtros avançados
    """
    queryset = Chamado.objects.all().select_related(
        'solicitante'
    ).prefetch_related(
        'responsaveis',
        'historico',
        'comentarios',
        'anexos'
    ).order_by('-data_criacao')

    filter_backends = [
        DjangoFilterBackend,
        filters.SearchFilter,
        filters.OrderingFilter
    ]

    filterset_class = ChamadoFilter

    search_fields = ['titulo', 'descricao', 'ativo', 'id']

    ordering_fields = [
        'data_criacao',
        'urgencia',
        'status',
        'data_atualizacao',
        'data_sugerida'
    ]

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return ChamadoWriteSerializer
        return ChamadoReadSerializer

    def get_queryset(self):
        """Aplica filtros de permissão baseado no usuário"""
        queryset = super().get_queryset()
        user = self.request.user

        if not user.is_staff and user.is_authenticated:
            queryset = queryset.filter(
                Q(solicitante=user) | Q(responsaveis=user)
            ).distinct()

        return queryset

    def perform_create(self, serializer):
        chamado = serializer.save(solicitante=self.request.user)

        ChamadoStatusHistory.objects.create(
            chamado=chamado,
            status=chamado.status,
            descricao=f"Chamado criado: {chamado.titulo}",
            usuario=self.request.user
        )

    @action(detail=True, methods=['post'])
    def mudar_status(self, request, pk=None):
        chamado = self.get_object()
        serializer = MudarStatusSerializer(data=request.data)

        if serializer.is_valid():
            novo_status = serializer.validated_data['status']
            descricao = serializer.validated_data['descricao']
            fotos = serializer.validated_data.get('fotos', [])

            chamado.status = novo_status
            chamado.save()

            historico = ChamadoStatusHistory.objects.create(
                chamado=chamado,
                status=novo_status,
                descricao=descricao,
                usuario=request.user
            )

            for foto in fotos:
                ChamadoStatusImage.objects.create(
                    historico=historico,
                    imagem=foto
                )

            return Response({
                'success': True,
                'message': 'Status atualizado com sucesso',
                'chamado': ChamadoReadSerializer(chamado, context={'request': request}).data
            })

        return Response({
            'success': False,
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def adicionar_comentario(self, request, pk=None):
        chamado = self.get_object()
        serializer = CriarComentarioSerializer(data=request.data)

        if serializer.is_valid():
         
         fotos = request.FILES.getlist('fotos')
         comentario = serializer.save(
              chamado=chamado,
              autor=request.user,
              fotos=fotos  
         )

        return Response({
            'success': True,
            'message': 'Comentário adicionado com sucesso',
            'comentario': ComentarioSerializer(comentario, context={'request': request}).data
        })

        return Response({
            'success': False,
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def adicionar_anexo(self, request, pk=None):
        chamado = self.get_object()
        arquivo = request.FILES.get('arquivo')

        if not arquivo:
            return Response({
                'success': False,
                'message': 'Nenhum arquivo enviado'
            }, status=status.HTTP_400_BAD_REQUEST)

        anexo = ChamadoAnexo.objects.create(
            chamado=chamado,
            arquivo=arquivo,
            nome_original=arquivo.name
        )

        return Response({
            'success': True,
            'message': 'Anexo adicionado com sucesso',
            'anexo': {
                'id': anexo.id,
                'nome': anexo.nome_original,
                'url': request.build_absolute_uri(anexo.arquivo.url)
            }
        })

    @action(detail=False, methods=['get'])
    def estatisticas(self, request):
        user = request.user

        queryset = Chamado.objects.all()
        if not user.is_staff:
            queryset = queryset.filter(
                Q(solicitante=user) | Q(responsaveis=user)
            ).distinct()

        total = queryset.count()

        por_status = queryset.values('status').annotate(
            total=Count('id')
        ).order_by('status')

        por_urgencia = queryset.values('urgencia').annotate(
            total=Count('id')
        ).order_by('urgencia')

        criticos_abertos = queryset.filter(
            urgencia__in=['Crítico', 'Alta'],
            status__in=['ABERTO', 'EM ANDAMENTO', 'AGUARDANDO RESP']
        ).count()

        mes_atual = timezone.now().replace(day=1, hour=0, minute=0, second=0)
        chamados_mes = queryset.filter(data_criacao__gte=mes_atual).count()

        return Response({
            'total_chamados': total,
            'por_status': list(por_status),
            'por_urgencia': list(por_urgencia),
            'criticos_abertos': criticos_abertos,
            'chamados_mes': chamados_mes,
        })

    @action(detail=False, methods=['get'])
    def estatisticas_filtradas(self, request):
        queryset = self.filter_queryset(self.get_queryset())

        total = queryset.count()

        por_status = queryset.values('status').annotate(
            total=Count('id')
        ).order_by('status')

        por_urgencia = queryset.values('urgencia').annotate(
            total=Count('id')
        ).order_by('urgencia')

        criticos_abertos = queryset.filter(
            urgencia__in=['Crítico', 'Alta'],
            status__in=['ABERTO', 'EM ANDAMENTO', 'AGUARDANDO RESP']
        ).count()

        return Response({
            'success': True,
            'total': total,
            'por_status': list(por_status),
            'por_urgencia': list(por_urgencia),
            'criticos_abertos': criticos_abertos,
        })

    @action(detail=False, methods=['post'], url_path='bulk-delete')
    def bulk_delete_chamados(self, request):
        ids = request.data.get("ids", None)

        if not ids or not isinstance(ids, list):
            return Response({
                "success": False,
                "message": "Envie uma lista de IDs válida no formato: { 'ids': [1,2,3] }"
            }, status=status.HTTP_400_BAD_REQUEST)

        queryset = self.get_queryset().filter(id__in=ids)

        encontrados = queryset.count()
        nao_encontrados = len(ids) - encontrados

        queryset.delete()
        return Response({
            "success": True,
            "message": "Chamados excluídos com sucesso.",
            "quantidade_excluida": encontrados,
            "nao_localizados_ou_sem_permissao": nao_encontrados,
            "ids_processados": ids
        })


# =========================
# EXPORT CSV
# =========================
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def export_chamados_csv(request):
    """
    Exporta os chamados usando os mesmos filtros do ChamadoViewSet
    """
    viewset = ChamadoViewSet()
    viewset.request = request

    queryset = viewset.filter_queryset(viewset.get_queryset())

    response = HttpResponse(content_type='text/csv')
    response['Content-Disposition'] = 'attachment; filename="chamados_exportados.csv"'

    writer = csv.writer(response)

    writer.writerow([
        "ID",
        "Título",
        "Descrição",
        "Status",
        "Urgência",
        "Solicitante",
        "Responsáveis",
        "Ativo",
        "Data Criação",
        "Data Atualização",
        "Data Sugerida"
    ])

    for chamado in queryset:
        writer.writerow([
            chamado.id,
            chamado.titulo,
            chamado.descricao,
            chamado.status,
            chamado.urgencia,
            chamado.solicitante.username if chamado.solicitante else "",
            ", ".join([u.username for u in chamado.responsaveis.all()]),
            chamado.ativo,
            chamado.data_criacao.strftime('%Y-%m-%d %H:%M'),
            chamado.data_atualizacao.strftime('%Y-%m-%d %H:%M') if chamado.data_atualizacao else "",
            chamado.data_sugerida.strftime('%Y-%m-%d %H:%M') if chamado.data_sugerida else "",
        ])

    return response


# =========================
# COMENTÁRIOS
# =========================
class ComentarioViewSet(viewsets.ModelViewSet):
    queryset = Comentario.objects.all().select_related('autor', 'chamado').order_by('-data_criacao')
    serializer_class = ComentarioSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['chamado', 'autor']

    def perform_create(self, serializer):
        serializer.save(autor=self.request.user)


# =========================
# ATIVOS
# =========================
class AtivoViewSet(viewsets.ModelViewSet):
    queryset = Ativo.objects.all().order_by('nome')
    serializer_class = AtivoSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = AtivoFilter

    search_fields = ['codigo', 'nome', 'modelo', 'fabricante', 'numero_serie']
    ordering_fields = ['nome', 'data_cadastro', 'status']

    @action(detail=True, methods=['get'])
    def por_qrcode(self, request, pk=None):
        codigo = pk

        try:
            ativo = Ativo.objects.get(codigo=codigo)
            return Response({
                'success': True,
                'ativo': AtivoSerializer(ativo, context={'request': request}).data
            })
        except Ativo.DoesNotExist:
            return Response({'success': False, 'message': 'Ativo não encontrado'}, status=status.HTTP_404_NOT_FOUND)

    @action(detail=True, methods=['get'], url_path='chamados')  # ADICIONAR url_path
    def chamados(self, request, pk=None):
        """
        GET /api/chamados/ativos/{id}/chamados/
        Retorna os chamados relacionados ao ativo
        """
        ativo = self.get_object()

        chamados = Chamado.objects.filter(
            ativo__icontains=ativo.codigo
        ).order_by('-data_criacao')

        serializer = ChamadoReadSerializer(chamados, many=True, context={'request': request})

        return Response({'success': True, 'chamados': serializer.data})

    # ADICIONAR ESTA ACTION PARA QR CODE
    @action(detail=True, methods=['get'], url_path='qr-code')
    def qr_code(self, request, pk=None):
        """
        GET /api/chamados/ativos/{id}/qr-code/
        Retorna o QR Code do ativo em base64
        """
        ativo = self.get_object()

        qr_base64 = QRCodeGenerator.gerar_qr_base64(
            ativo.codigo,
            label=f"{ativo.codigo}\n{ativo.nome}",
            com_label=True
        )

        return Response({
            'success': True,
            'ativo_id': ativo.id,
            'ativo_codigo': ativo.codigo,
            'ativo_nome': ativo.nome,
            'qr_code': f'data:image/png;base64,{qr_base64}',
            'formato': 'PNG',
        })

    @action(detail=True, methods=['post'])
    def adicionar_historico(self, request, pk=None):
        ativo = self.get_object()

        tipo = request.data.get('tipo')
        descricao = request.data.get('descricao')

        if not tipo or not descricao:
            return Response({'success': False, 'message': 'Tipo e descrição são obrigatórios'}, status=status.HTTP_400_BAD_REQUEST)

        AtivoHistorico.objects.create(
            ativo=ativo,
            tipo=tipo,
            descricao=descricao,
            usuario=request.user
        )

        return Response({'success': True, 'message': 'Histórico adicionado com sucesso'})
# =========================
# USUÁRIOS
# =========================
# Mude de ReadOnlyModelViewSet para ModelViewSet
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all().order_by('username')
    serializer_class = UserSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['username', 'first_name', 'last_name', 'email']
    
    # Protege a edição: Apenas Superusuários/Staff podem criar/editar/deletar
    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminUser()]
        return [IsAuthenticated()]

    @action(detail=False, methods=['get'])
    def me(self, request):
        if request.user.is_authenticated:
            return Response({'success': True, 'user': UserSerializer(request.user).data})
        return Response({'success': False, 'message': 'Usuário não autenticado'}, status=status.HTTP_401_UNAUTHORIZED)

# =========================
# DASHBOARD GERENCIAL
# =========================
@api_view(['GET'])
def dashboard_gerencial(request):
    user = request.user

    queryset = Chamado.objects.all()
    if not user.is_staff:
        queryset = queryset.filter(Q(solicitante=user) | Q(responsaveis=user)).distinct()

    total_chamados = queryset.count()

    abertos = queryset.filter(status='ABERTO').count()
    em_andamento = queryset.filter(status='EM ANDAMENTO').count()
    aguardando = queryset.filter(status='AGUARDANDO RESP').count()
    realizado = queryset.filter(status='REALIZADO').count()
    concluido = queryset.filter(status='CONCLUÍDO').count()
    cancelado = queryset.filter(status='CANCELADO').count()

    criticos = queryset.filter(
        urgencia__in=['Crítico', 'Alta'],
        status__in=['ABERTO', 'EM ANDAMENTO', 'AGUARDANDO RESP']
    )

    criticos_detalhes = ChamadoReadSerializer(criticos[:10], many=True, context={'request': request}).data

    por_urgencia = {
        'critico': queryset.filter(urgencia='Crítico').count(),
        'alta': queryset.filter(urgencia='Alta').count(),
        'media': queryset.filter(urgencia='Média').count(),
        'baixa': queryset.filter(urgencia='Baixa').count(),
    }

    tempo_medio = "4.2h"

    hoje = timezone.now()
    ultimos_7_dias = queryset.filter(data_criacao__gte=hoje - timedelta(days=7)).count()
    ultimos_30_dias = queryset.filter(data_criacao__gte=hoje - timedelta(days=30)).count()
    ultimos_90_dias = queryset.filter(data_criacao__gte=hoje - timedelta(days=90)).count()

    tempo_resolucao = {
        'menos_1h': 120,
        '1_2h': 210,
        '2_4h': 350,
        '4_8h': 280,
        '8_12h': 150,
        '12_24h': 90,
        'mais_24h': 48
    }

    return Response({
        'success': True,
        'data': {
            'kpis': {
                'total_chamados': total_chamados,
                'abertos': abertos,
                'em_andamento': em_andamento,
                'aguardando': aguardando,
                'realizado': realizado,
                'concluido': concluido,
                'cancelado': cancelado,
                'criticos_abertos': criticos.count(),
                'tempo_medio': tempo_medio,
            },
            'por_status': {
                'aberto': abertos,
                'em_andamento': em_andamento,
                'aguardando': aguardando,
                'realizado': realizado,
                'concluido': concluido,
                'cancelado': cancelado,
            },
            'por_urgencia': por_urgencia,
            'periodo': {
                'ultimos_7_dias': ultimos_7_dias,
                'ultimos_30_dias': ultimos_30_dias,
                'ultimos_90_dias': ultimos_90_dias,
            },
            'tempo_resolucao': tempo_resolucao,
            'criticos': criticos_detalhes,
        }
    })


# =========================
# PERFIL DO USUÁRIO
# =========================
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    user = request.user

    return Response({
        'success': True,
        'data': {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'is_staff': user.is_staff,
            'date_joined': user.date_joined.strftime('%Y-%m-%d'),
        }
    })


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_user_profile(request):
    user = request.user
    data = request.data

    errors = {}

    if 'email' in data:
        email = data['email'].strip()
        if not email:
            errors['email'] = 'Email não pode estar vazio'
        elif User.objects.filter(email=email).exclude(id=user.id).exists():
            errors['email'] = 'Este email já está em uso'
        else:
            # atualizar email (não altera username automaticamente)
            user.email = email
            # se você quiser que username seja o email, descomente a linha abaixo:
            # user.username = email

    if 'username' in data:
        username = data['username'].strip()
        if not username:
            errors['username'] = 'Usuário não pode estar vazio'
        elif len(username) < 3:
            errors['username'] = 'Usuário deve ter pelo menos 3 caracteres'
        elif User.objects.filter(username=username).exclude(id=user.id).exists():
            errors['username'] = 'Este nome de usuário já está em uso'
        else:
            user.username = username

    if 'first_name' in data:
        first_name = data['first_name'].strip()
        if not first_name:
            errors['first_name'] = 'Nome não pode estar vazio'
        else:
            user.first_name = first_name

    if 'last_name' in data:
        last_name = data['last_name'].strip()
        if not last_name:
            errors['last_name'] = 'Sobrenome não pode estar vazio'
        else:
            user.last_name = last_name

    if errors:
        return Response({'success': False, 'errors': errors}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user.save()
        return Response({
            'success': True,
            'message': 'Perfil atualizado com sucesso',
            'data': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
            }
        })

    except Exception as e:
        return Response({'success': False, 'message': f'Erro ao atualizar perfil: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    user = request.user
    data = request.data

    senha_atual = data.get('senha_atual')
    nova_senha = data.get('nova_senha')
    confirmar_senha = data.get('confirmar_senha')

    errors = {}

    if not senha_atual:
        errors['senha_atual'] = 'Senha atual é obrigatória'
    elif not user.check_password(senha_atual):
        errors['senha_atual'] = 'Senha atual incorreta'

    if not nova_senha:
        errors['nova_senha'] = 'Nova senha é obrigatória'
    elif len(nova_senha) < 6:
        errors['nova_senha'] = 'Nova senha deve ter pelo menos 6 caracteres'

    if not confirmar_senha:
        errors['confirmar_senha'] = 'Confirmação de senha é obrigatória'
    elif nova_senha != confirmar_senha:
        errors['confirmar_senha'] = 'Senhas não conferem'

    if errors:
        return Response({'success': False, 'errors': errors}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user.set_password(nova_senha)
        user.save()

        Token.objects.filter(user=user).delete()
        new_token = Token.objects.create(user=user)

        return Response({'success': True, 'message': 'Senha alterada com sucesso', 'token': new_token.key})

    except Exception as e:
        return Response({'success': False, 'message': f'Erro ao alterar senha: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_statistics(request):
    user = request.user

    chamados = Chamado.objects.filter(Q(solicitante=user) | Q(responsaveis=user)).distinct()

    por_status = chamados.values('status').annotate(total=Count('id')).order_by('status')
    por_urgencia = chamados.values('urgencia').annotate(total=Count('id')).order_by('urgencia')

    total_chamados = chamados.count()
    chamados_solicitados = Chamado.objects.filter(solicitante=user).count()
    chamados_responsavel = Chamado.objects.filter(responsaveis=user).count()

    chamados_ativos = chamados.filter(status__in=['ABERTO', 'EM ANDAMENTO', 'AGUARDANDO RESP', 'REALIZADO']).count()

    return Response({
        'success': True,
        'data': {
            'total_chamados': total_chamados,
            'chamados_solicitados': chamados_solicitados,
            'chamados_responsavel': chamados_responsavel,
            'chamados_ativos': chamados_ativos,
            'por_status': list(por_status),
            'por_urgencia': list(por_urgencia),
        }
    })
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_statistics_by_id(request, user_id):
    """
    Retorna estatísticas de chamados de um usuário específico
    Apenas admins podem ver estatísticas de outros usuários
    """
    # Verifica se é admin ou está vendo o próprio perfil
    if not request.user.is_staff and request.user.id != user_id:
        return Response({
            'success': False,
            'message': 'Você não tem permissão para visualizar estas estatísticas'
        }, status=status.HTTP_403_FORBIDDEN)
    
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Usuário não encontrado'
        }, status=status.HTTP_404_NOT_FOUND)

    # Busca chamados relacionados ao usuário
    chamados = Chamado.objects.filter(
        Q(solicitante=user) | Q(responsaveis=user)
    ).distinct()

    # Estatísticas por status
    por_status = chamados.values('status').annotate(
        total=Count('id')
    ).order_by('status')

    # Estatísticas por urgência
    por_urgencia = chamados.values('urgencia').annotate(
        total=Count('id')
    ).order_by('urgencia')

    # Contagens
    total_chamados = chamados.count()
    chamados_solicitados = Chamado.objects.filter(solicitante=user).count()
    chamados_responsavel = Chamado.objects.filter(responsaveis=user).count()
    chamados_ativos = chamados.filter(
        status__in=['ABERTO', 'EM ANDAMENTO', 'AGUARDANDO RESP', 'REALIZADO']
    ).count()

    return Response({
        'success': True,
        'data': {
            'total_chamados': total_chamados,
            'chamados_solicitados': chamados_solicitados,
            'chamados_responsavel': chamados_responsavel,
            'chamados_ativos': chamados_ativos,
            'por_status': list(por_status),
            'por_urgencia': list(por_urgencia),
        }
    })


# =========================
# ENDPOINTS QR CODE
# =========================
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def gerar_qr_code_ativo(request, pk):
    """
    GET /api/ativos/{id}/qr-code/
    Retorna QR code do ativo em base64
    """
    try:
        ativo = Ativo.objects.get(pk=pk)

        qr_base64 = QRCodeGenerator.gerar_qr_base64(
            ativo.codigo,
            label=f"{ativo.codigo}\n{ativo.nome}",
            com_label=True
        )

        return Response({
            'success': True,
            'ativo_id': ativo.id,
            'ativo_codigo': ativo.codigo,
            'qr_code': f'data:image/png;base64,{qr_base64}',
            'formato': 'PNG',
        })
    except Ativo.DoesNotExist:
        return Response({'success': False, 'message': 'Ativo não encontrado'}, status=404)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def gerar_qr_code_por_codigo(request, codigo):
    """
    GET /api/ativos/qr-code/{codigo}/
    Retorna QR code do ativo pelo código
    """
    try:
        qr_base64 = QRCodeGenerator.gerar_qr_base64(codigo)

        return Response({
            'success': True,
            'ativo_codigo': codigo,
            'qr_code': f'data:image/png;base64,{qr_base64}',
            'formato': 'PNG',
        })
    except Exception as e:
        return Response({'success': False, 'message': str(e)}, status=400)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def listar_qr_codes_ativos(request):
    """
    GET /api/ativos/qr-codes/
    Retorna QR codes de todos os ativos
    """
    try:
        ativos = Ativo.objects.all()

        qr_codes = []
        for ativo in ativos:
            qr_base64 = QRCodeGenerator.gerar_qr_base64(
                ativo.codigo,
                label=f"{ativo.codigo}\n{ativo.nome}",
                com_label=True
            )

            qr_codes.append({
                'ativo_id': ativo.id,
                'ativo_codigo': ativo.codigo,
                'ativo_nome': ativo.nome,
                'qr_code': f'data:image/png;base64,{qr_base64}',
            })

        return Response({'success': True, 'total': len(qr_codes), 'qr_codes': qr_codes})
    except Exception as e:
        return Response({'success': False, 'message': str(e)}, status=400)
