import csv
from datetime import timedelta

from django.contrib.auth.models import User, update_last_login
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import transaction
from django.db.models import Count, Min, Q
from django.http import HttpResponse
from django.utils import timezone
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters, status, viewsets
from rest_framework.authtoken.models import Token
from rest_framework.decorators import action, api_view, permission_classes, throttle_classes
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import AllowAny, IsAdminUser, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import SimpleRateThrottle

from .email_service import EnviadorEmail, VerificadorEmail
from .filters import AtivoFilter, ChamadoFilter
from .models import (
    Ativo,
    AtivoHistorico,
    Chamado,
    ChamadoAnexo,
    ChamadoStatusHistory,
    ChamadoStatusImage,
    Comentario,
    TokenRecuperacaoSenha,
    VerificacaoEmail,
)
from .qr_generator import QRCodeGenerator
from .serializers import (
    TAMANHO_MAX_ANEXO,
    AtivoHistoricoSerializer,
    AtivoSerializer,
    ChamadoAnexoSerializer,
    ChamadoReadSerializer,
    ChamadoWriteSerializer,
    ComentarioSerializer,
    CriarComentarioSerializer,
    MudarStatusSerializer,
    UserRegistrationSerializer,
    UserSerializer,
)

STATUS_EM_ABERTO = ['ABERTO', 'AGUARDANDO RESP', 'EM ANDAMENTO']
STATUS_RESOLVIDO = ['REALIZADO', 'CONCLUÍDO']


# =========================
# APOIO
# =========================

def _erro(mensagem, http=status.HTTP_400_BAD_REQUEST, **extra):
    return Response({'success': False, 'message': mensagem, **extra}, status=http)


def _chamados_visiveis(user):
    """Staff vê tudo; os demais, só os chamados em que são solicitante ou responsável.

    Usa subconsulta de ids em vez de .distinct() para que contagens agrupadas
    (values().annotate()) não contem o mesmo chamado duas vezes.
    """
    qs = Chamado.objects.all()
    if user.is_staff:
        return qs
    ids = Chamado.objects.filter(Q(solicitante=user) | Q(responsaveis=user)).values('pk')
    return qs.filter(pk__in=ids)


def _primeiro_erro(errors):
    """Primeira mensagem legível de um dict de erros do DRF."""
    if isinstance(errors, dict):
        for valor in errors.values():
            return _primeiro_erro(valor)
    if isinstance(errors, (list, tuple)) and errors:
        return _primeiro_erro(errors[0])
    return str(errors)


def _mascarar_email(email: str) -> str:
    nome, _, dominio = email.partition('@')
    if len(nome) > 2:
        nome = nome[0] + '*' * (len(nome) - 2) + nome[-1]
    else:
        nome = '*' * len(nome)
    return f'{nome}@{dominio}'


def _usuario_por_email(email: str):
    email = (email or '').strip()
    if not email:
        return None
    return (
        User.objects.filter(email__iexact=email).order_by('-is_active', 'id').first()
        or User.objects.filter(username__iexact=email).first()
    )


def _formatar_horas(horas):
    if horas is None:
        return '—'
    if horas < 48:
        return f'{horas:.1f}h'
    return f'{horas / 24:.1f} dias'


class AuthThrottle(SimpleRateThrottle):
    """Limite por IP nos endpoints públicos de login/cadastro/recuperação."""

    scope = 'auth'

    def get_cache_key(self, request, view):
        return self.cache_format % {'scope': self.scope, 'ident': self.get_ident(request)}


# =========================
# AUTENTICAÇÃO
# =========================

@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([AuthThrottle])
def register_user(request):
    serializer = UserRegistrationSerializer(data=request.data)
    if not serializer.is_valid():
        return Response({
            'success': False,
            'message': _primeiro_erro(serializer.errors),
            'errors': serializer.errors,
        }, status=status.HTTP_400_BAD_REQUEST)

    user = serializer.save()
    token, _ = Token.objects.get_or_create(user=user)
    update_last_login(None, user)
    return Response({
        'success': True,
        'message': 'Usuário criado com sucesso!',
        'user': UserSerializer(user).data,
        'token': token.key,
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([AuthThrottle])
def login_user(request):
    email = str(request.data.get('email', '')).strip()
    senha = str(request.data.get('senha', ''))

    if not email or not senha:
        return _erro('E-mail e senha são obrigatórios.')

    user = _usuario_por_email(email)
    if not user or not user.check_password(senha):
        return _erro('E-mail ou senha incorretos.', status.HTTP_401_UNAUTHORIZED)

    if not user.is_active:
        return _erro('Sua conta está inativa. Fale com o administrador.', status.HTTP_401_UNAUTHORIZED)

    token, _ = Token.objects.get_or_create(user=user)
    update_last_login(None, user)
    return Response({
        'success': True,
        'message': 'Login realizado com sucesso!',
        'user': UserSerializer(user).data,
        'token': token.key,
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_user(request):
    Token.objects.filter(user=request.user).delete()
    return Response({'success': True, 'message': 'Logout realizado com sucesso.'})


MENSAGEM_RECUPERACAO = 'Se o e-mail estiver cadastrado, você vai receber um código de 6 dígitos.'


@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([AuthThrottle])
def solicitar_recuperacao_senha(request):
    email = str(request.data.get('email', '')).strip().lower()
    if not email:
        return _erro('E-mail é obrigatório.')
    if not VerificadorEmail.validar_sintaxe(email):
        return _erro('E-mail inválido.')

    resposta = {
        'success': True,
        'message': MENSAGEM_RECUPERACAO,
        'email_mascarado': _mascarar_email(email),
        'tempo_expiracao': 15,
    }

    usuario = _usuario_por_email(email)
    if not usuario or not usuario.is_active:
        # Mesma resposta de quando existe: não revela quem tem conta.
        return Response(resposta)

    # Evita disparar vários e-mails seguidos para a mesma pessoa.
    recente = TokenRecuperacaoSenha.objects.filter(
        user=usuario, criado_em__gte=timezone.now() - timedelta(seconds=55), ativo=True
    ).exists()
    if recente:
        return Response(resposta)

    token_obj = TokenRecuperacaoSenha.criar_para_usuario(usuario, usuario.email or email)
    if not EnviadorEmail.enviar_token_recuperacao(usuario, token_obj):
        token_obj.delete()
        return _erro('Não foi possível enviar o e-mail agora. Tente de novo em alguns minutos.',
                     status.HTTP_503_SERVICE_UNAVAILABLE)
    return Response(resposta)


# Endpoint antigo; mantido como apelido do novo.
recuperar_senha = solicitar_recuperacao_senha


def _token_do_pedido(request):
    email = str(request.data.get('email', '')).strip()
    token = str(request.data.get('token', '')).strip()
    if not email or not token:
        return None, None, _erro('E-mail e código são obrigatórios.')
    usuario = _usuario_por_email(email)
    token_obj = TokenRecuperacaoSenha.objects.filter(user=usuario).first() if usuario else None
    if not token_obj:
        return None, None, _erro('Código inválido ou expirado. Peça um novo código.', token_expirado=True)
    return usuario, token_obj, None


def _resposta_token_errado(token_obj):
    restantes = max(token_obj.max_tentativas - token_obj.tentativas, 0)
    if restantes == 0 or not token_obj.is_valido():
        return _erro('Código expirado ou com tentativas esgotadas. Peça um novo código.', token_expirado=True)
    return _erro(f'Código incorreto. {restantes} tentativa(s) restante(s).', tentativas_restantes=restantes)


@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([AuthThrottle])
def verificar_token_recuperacao(request):
    """Confere o código sem consumi-lo; o consumo acontece em resetar-senha."""
    usuario, token_obj, erro = _token_do_pedido(request)
    if erro:
        return erro
    if not token_obj.conferir(request.data.get('token', '')):
        return _resposta_token_errado(token_obj)
    return Response({'success': True, 'message': 'Código conferido.', 'usuario_id': usuario.id})


@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([AuthThrottle])
def resetar_senha(request):
    nova_senha = str(request.data.get('nova_senha') or request.data.get('senha') or '')
    confirmar = str(request.data.get('confirmar_senha') or nova_senha)

    if len(nova_senha) < 6:
        return _erro('A senha precisa ter pelo menos 6 caracteres.')
    if nova_senha != confirmar:
        return _erro('As senhas não conferem.')

    usuario, token_obj, erro = _token_do_pedido(request)
    if erro:
        return erro

    with transaction.atomic():
        if not token_obj.verificar_token(request.data.get('token', '')):
            return _resposta_token_errado(token_obj)
        usuario.set_password(nova_senha)
        usuario.save(update_fields=['password'])
        Token.objects.filter(user=usuario).delete()  # derruba sessões abertas

    EnviadorEmail.enviar_confirmacao_resetar_senha(usuario)
    return Response({'success': True, 'message': 'Senha redefinida. Entre com a nova senha.'})


@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([AuthThrottle])
def verificar_email_real(request):
    email = str(request.data.get('email', '')).strip().lower()
    if not email:
        return _erro('E-mail é obrigatório.')

    resultado = VerificadorEmail.verificar_email_completo(email)
    VerificacaoEmail.objects.update_or_create(
        email=email,
        defaults={
            'status': 'VERIFICADO' if resultado['valido'] else 'REJEITADO',
            'dominio_valido': resultado['dominio_ok'],
            'email_real': resultado['valido'],
            'verificado_em': timezone.now() if resultado['valido'] else None,
        },
    )
    corpo = {
        'success': resultado['valido'],
        'email': email,
        'valido': resultado['valido'],
        'mensagem': resultado['mensagem'],
        'message': resultado['mensagem'],
        'detalhes': resultado,
    }
    return Response(corpo, status=status.HTTP_200_OK if resultado['valido'] else status.HTTP_400_BAD_REQUEST)


# =========================
# CHAMADOS
# =========================

class ChamadoViewSet(viewsets.ModelViewSet):
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_class = ChamadoFilter
    ordering_fields = ['id', 'data_criacao', 'urgencia', 'status', 'data_atualizacao', 'data_sugerida', 'titulo']
    ordering = ['-data_criacao']

    def get_serializer_class(self):
        if self.action in ('create', 'update', 'partial_update'):
            return ChamadoWriteSerializer
        return ChamadoReadSerializer

    def get_queryset(self):
        return _chamados_visiveis(self.request.user).select_related(
            'solicitante', 'ativo_ref'
        ).prefetch_related(
            'responsaveis',
            'historico__usuario',
            'historico__fotos',
            'comentarios__autor',
            'comentarios__fotos',
            'anexos',
        )

    def perform_create(self, serializer):
        chamado = serializer.save(solicitante=self.request.user)
        ChamadoStatusHistory.objects.create(
            chamado=chamado,
            status=chamado.status,
            descricao=f'Chamado criado: {chamado.titulo}',
            usuario=self.request.user,
        )
        if chamado.ativo_ref_id:
            AtivoHistorico.objects.create(
                ativo=chamado.ativo_ref,
                tipo='Chamado aberto',
                descricao=f'Chamado #{chamado.id}: {chamado.titulo}',
                usuario=self.request.user,
            )

    def perform_update(self, serializer):
        status_antes = serializer.instance.status
        chamado = serializer.save()
        if chamado.status != status_antes:
            ChamadoStatusHistory.objects.create(
                chamado=chamado,
                status=chamado.status,
                descricao=f'Status alterado de {status_antes} para {chamado.status} na edição do chamado.',
                usuario=self.request.user,
            )

    def destroy(self, request, *args, **kwargs):
        chamado = self.get_object()
        if not request.user.is_staff and chamado.solicitante_id != request.user.id:
            return _erro('Só quem abriu o chamado ou um administrador pode excluí-lo.', status.HTTP_403_FORBIDDEN)
        try:
            chamado.delete()
        except DjangoValidationError as exc:
            return _erro(exc.messages[0])
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['post'])
    def mudar_status(self, request, pk=None):
        chamado = self.get_object()
        serializer = MudarStatusSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                'success': False,
                'message': _primeiro_erro(serializer.errors),
                'errors': serializer.errors,
            }, status=status.HTTP_400_BAD_REQUEST)

        dados = serializer.validated_data
        with transaction.atomic():
            chamado.status = dados['status']
            chamado.save(update_fields=['status', 'data_atualizacao'])
            historico = ChamadoStatusHistory.objects.create(
                chamado=chamado,
                status=dados['status'],
                descricao=dados['descricao'],
                usuario=request.user,
            )
            for foto in dados.get('fotos', []):
                ChamadoStatusImage.objects.create(historico=historico, imagem=foto)

        chamado = self.get_queryset().get(pk=chamado.pk)
        return Response({
            'success': True,
            'message': 'Status atualizado com sucesso.',
            'chamado': ChamadoReadSerializer(chamado, context={'request': request}).data,
        })

    @action(detail=True, methods=['post'])
    def adicionar_comentario(self, request, pk=None):
        chamado = self.get_object()
        serializer = CriarComentarioSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                'success': False,
                'message': _primeiro_erro(serializer.errors),
                'errors': serializer.errors,
            }, status=status.HTTP_400_BAD_REQUEST)

        comentario = serializer.save(chamado=chamado, autor=request.user)
        Chamado.objects.filter(pk=chamado.pk).update(data_atualizacao=timezone.now())
        return Response({
            'success': True,
            'message': 'Comentário adicionado com sucesso.',
            'comentario': ComentarioSerializer(comentario, context={'request': request}).data,
        }, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def adicionar_anexo(self, request, pk=None):
        chamado = self.get_object()
        arquivo = request.FILES.get('arquivo')
        if not arquivo:
            return _erro('Nenhum arquivo enviado.')
        if arquivo.size > TAMANHO_MAX_ANEXO:
            return _erro('O anexo pode ter no máximo 20 MB.')

        anexo = ChamadoAnexo.objects.create(chamado=chamado, arquivo=arquivo, nome_original=arquivo.name[:255])
        dados = ChamadoAnexoSerializer(anexo, context={'request': request}).data
        dados['nome'] = anexo.nome_original  # campo antigo
        return Response({'success': True, 'message': 'Anexo adicionado com sucesso.', 'anexo': dados},
                        status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['delete'], url_path=r'anexos/(?P<anexo_id>\d+)')
    def remover_anexo(self, request, pk=None, anexo_id=None):
        chamado = self.get_object()
        anexo = chamado.anexos.filter(pk=anexo_id).first()
        if not anexo:
            return _erro('Anexo não encontrado.', status.HTTP_404_NOT_FOUND)
        anexo.arquivo.delete(save=False)
        anexo.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    def _estatisticas(self, queryset):
        return {
            'total': queryset.count(),
            'por_status': list(queryset.values('status').annotate(total=Count('id')).order_by('status')),
            'por_urgencia': list(queryset.values('urgencia').annotate(total=Count('id')).order_by('urgencia')),
            'criticos_abertos': queryset.filter(urgencia__in=['Crítico', 'Alta'], status__in=STATUS_EM_ABERTO).count(),
        }

    @action(detail=False, methods=['get'])
    def estatisticas(self, request):
        queryset = _chamados_visiveis(request.user)
        dados = self._estatisticas(queryset)
        inicio_mes = timezone.localtime().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        return Response({
            'total_chamados': dados['total'],
            'por_status': dados['por_status'],
            'por_urgencia': dados['por_urgencia'],
            'criticos_abertos': dados['criticos_abertos'],
            'chamados_mes': queryset.filter(data_criacao__gte=inicio_mes).count(),
        })

    @action(detail=False, methods=['get'])
    def estatisticas_filtradas(self, request):
        queryset = self.filter_queryset(_chamados_visiveis(request.user))
        return Response({'success': True, **self._estatisticas(queryset)})

    @action(detail=False, methods=['post'], url_path='bulk-delete')
    def bulk_delete_chamados(self, request):
        ids = request.data.get('ids')
        if not isinstance(ids, list) or not ids:
            return _erro('Envie uma lista de ids no formato {"ids": [1, 2, 3]}.')
        try:
            ids = [int(i) for i in ids]
        except (TypeError, ValueError):
            return _erro('Os ids precisam ser números.')

        queryset = _chamados_visiveis(request.user).filter(id__in=ids)
        if not request.user.is_staff:
            queryset = queryset.filter(solicitante=request.user)

        em_andamento = list(queryset.filter(status='EM ANDAMENTO').values_list('id', flat=True))
        excluir = queryset.exclude(status='EM ANDAMENTO')
        excluidos = list(excluir.values_list('id', flat=True))
        excluir.delete()

        return Response({
            'success': True,
            'message': f'{len(excluidos)} chamado(s) excluído(s).',
            'quantidade_excluida': len(excluidos),
            'ids_excluidos': excluidos,
            'ids_em_andamento': em_andamento,
            'nao_localizados_ou_sem_permissao': len(ids) - len(excluidos) - len(em_andamento),
        })

    @action(detail=False, methods=['get'], url_path='export')
    def export(self, request):
        """CSV com os mesmos filtros da listagem (separador ; e BOM para abrir no Excel)."""
        queryset = self.filter_queryset(self.get_queryset())

        response = HttpResponse(content_type='text/csv; charset=utf-8')
        response['Content-Disposition'] = (
            f'attachment; filename="chamados_{timezone.localdate():%Y-%m-%d}.csv"'
        )
        response.write('﻿')
        writer = csv.writer(response, delimiter=';')
        writer.writerow([
            'Nº', 'Título', 'Descrição', 'Status', 'Urgência', 'Ativo', 'Ambiente',
            'Solicitante', 'Responsáveis', 'Criado em', 'Atualizado em', 'Data sugerida',
        ])

        def fmt(data):
            return timezone.localtime(data).strftime('%d/%m/%Y %H:%M') if data else ''

        for chamado in queryset:
            writer.writerow([
                chamado.id,
                chamado.titulo,
                chamado.descricao,
                chamado.status,
                chamado.urgencia,
                chamado.ativo,
                chamado.ambiente,
                (chamado.solicitante.get_full_name() or chamado.solicitante.username) if chamado.solicitante else '',
                ', '.join(u.get_full_name() or u.username for u in chamado.responsaveis.all()),
                fmt(chamado.data_criacao),
                fmt(chamado.data_atualizacao),
                fmt(chamado.data_sugerida),
            ])
        return response


# =========================
# COMENTÁRIOS
# =========================

class ComentarioViewSet(viewsets.ModelViewSet):
    serializer_class = ComentarioSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['chamado', 'autor']

    def get_queryset(self):
        visiveis = _chamados_visiveis(self.request.user).values('pk')
        return Comentario.objects.filter(chamado__in=visiveis).select_related('autor', 'chamado') \
            .prefetch_related('fotos').order_by('-data_criacao')

    def perform_create(self, serializer):
        chamado = serializer.validated_data['chamado']
        if not _chamados_visiveis(self.request.user).filter(pk=chamado.pk).exists():
            raise PermissionDenied('Você não tem acesso a este chamado.')
        serializer.save(autor=self.request.user)

    def _checar_autor(self, comentario):
        if not self.request.user.is_staff and comentario.autor_id != self.request.user.id:
            raise PermissionDenied('Só o autor ou um administrador pode alterar este comentário.')

    def perform_update(self, serializer):
        self._checar_autor(serializer.instance)
        serializer.save()

    def perform_destroy(self, instance):
        self._checar_autor(instance)
        instance.delete()


# =========================
# ATIVOS
# =========================

class AtivoViewSet(viewsets.ModelViewSet):
    serializer_class = AtivoSerializer
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_class = AtivoFilter
    ordering_fields = ['nome', 'codigo', 'data_cadastro', 'status', 'ambiente']
    ordering = ['nome']

    def get_queryset(self):
        return Ativo.objects.annotate(
            n_chamados=Count('chamados', distinct=True),
            n_chamados_abertos=Count('chamados', filter=Q(chamados__status__in=STATUS_EM_ABERTO), distinct=True),
        ).prefetch_related('historico_movimentacoes__usuario')

    def get_permissions(self):
        # Cadastrar e excluir é do administrador; editar e registrar histórico, de todos.
        if self.action in ('create', 'destroy'):
            return [IsAdminUser()]
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        ativo = serializer.save()
        AtivoHistorico.objects.create(
            ativo=ativo, tipo='Cadastro', descricao='Ativo cadastrado no sistema.', usuario=self.request.user,
        )

    def perform_update(self, serializer):
        antes = serializer.instance
        status_antes, ambiente_antes = antes.status, antes.ambiente
        ativo = serializer.save()
        if ativo.status != status_antes:
            AtivoHistorico.objects.create(
                ativo=ativo, tipo='Mudança de status',
                descricao=f'Status alterado de {status_antes} para {ativo.status}.',
                usuario=self.request.user,
            )
        if ativo.ambiente != ambiente_antes:
            AtivoHistorico.objects.create(
                ativo=ativo, tipo='Movimentação',
                descricao=f'Transferido de "{ambiente_antes}" para "{ativo.ambiente}".',
                usuario=self.request.user,
            )

    def destroy(self, request, *args, **kwargs):
        ativo = self.get_object()
        abertos = ativo.chamados.filter(status__in=STATUS_EM_ABERTO).count()
        if abertos:
            return _erro(f'Este ativo tem {abertos} chamado(s) em aberto. Conclua ou cancele antes de excluir.')
        ativo.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['get'])
    def por_qrcode(self, request, pk=None):
        """GET /api/ativos/{codigo}/por_qrcode/ — busca pelo código lido no QR."""
        ativo = self.get_queryset().filter(codigo__iexact=pk).first()
        if not ativo:
            return _erro('Ativo não encontrado.', status.HTTP_404_NOT_FOUND)
        return Response({'success': True, 'ativo': AtivoSerializer(ativo, context={'request': request}).data})

    @action(detail=False, methods=['get'], url_path='por-codigo')
    def por_codigo(self, request):
        """GET /api/ativos/por-codigo/?codigo=AST-001 — aceita códigos com ponto."""
        codigo = (request.query_params.get('codigo') or '').strip()
        ativo = self.get_queryset().filter(codigo__iexact=codigo).first() if codigo else None
        if not ativo:
            return _erro('Ativo não encontrado.', status.HTTP_404_NOT_FOUND)
        return Response({'success': True, 'ativo': AtivoSerializer(ativo, context={'request': request}).data})

    @action(detail=True, methods=['get'], url_path='chamados')
    def chamados(self, request, pk=None):
        ativo = self.get_object()
        chamados = _chamados_visiveis(request.user).filter(ativo_ref=ativo).select_related(
            'solicitante', 'ativo_ref'
        ).prefetch_related('responsaveis').order_by('-data_criacao')
        dados = [
            {
                'id': str(c.id),
                'titulo': c.titulo,
                'status': c.status,
                'urgencia': c.urgencia,
                'data_criacao': c.data_criacao,
                'solicitante_nome': (c.solicitante.get_full_name() or c.solicitante.username) if c.solicitante else None,
                'responsaveis_nomes': [r.get_full_name() or r.username for r in c.responsaveis.all()],
            }
            for c in chamados
        ]
        return Response({'success': True, 'chamados': dados})

    @action(detail=True, methods=['get'], url_path='qr-code')
    def qr_code(self, request, pk=None):
        ativo = self.get_object()
        qr_base64 = QRCodeGenerator.gerar_qr_base64(ativo.codigo, label=f'{ativo.codigo}\n{ativo.nome}')
        return Response({
            'success': True,
            'ativo_id': ativo.id,
            'ativo_codigo': ativo.codigo,
            'ativo_nome': ativo.nome,
            'ativo_modelo': ativo.modelo,
            'ativo_ambiente': ativo.ambiente,
            'qr_code': f'data:image/png;base64,{qr_base64}',
            'formato': 'PNG',
        })

    @action(detail=True, methods=['get'], url_path='qr-code/png')
    def qr_code_png(self, request, pk=None):
        ativo = self.get_object()
        png = QRCodeGenerator.gerar_png(ativo.codigo, label=f'{ativo.codigo}\n{ativo.nome}')
        response = HttpResponse(png, content_type='image/png')
        response['Content-Disposition'] = f'inline; filename="qrcode-{ativo.codigo}.png"'
        return response

    @action(detail=True, methods=['post'])
    def adicionar_historico(self, request, pk=None):
        ativo = self.get_object()
        tipo = str(request.data.get('tipo', '')).strip()
        descricao = str(request.data.get('descricao', '')).strip()
        if not tipo or not descricao:
            return _erro('Tipo e descrição são obrigatórios.')

        item = AtivoHistorico.objects.create(ativo=ativo, tipo=tipo[:100], descricao=descricao, usuario=request.user)
        return Response({
            'success': True,
            'message': 'Histórico adicionado com sucesso.',
            'historico': AtivoHistoricoSerializer(item).data,
        }, status=status.HTTP_201_CREATED)


# =========================
# USUÁRIOS
# =========================

class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['username', 'first_name', 'last_name', 'email']
    ordering_fields = ['first_name', 'username', 'date_joined', 'last_login']
    ordering = ['first_name', 'username']
    # Usuários nascem pelo cadastro (auth/register), não por este endpoint.
    http_method_names = ['get', 'put', 'patch', 'delete', 'head', 'options']

    def get_queryset(self):
        qs = User.objects.all()
        if not self.request.user.is_staff:
            qs = qs.filter(is_active=True)  # para escolher responsáveis
        return qs

    def get_permissions(self):
        if self.action in ('update', 'partial_update', 'destroy'):
            return [IsAdminUser()]
        return [IsAuthenticated()]

    def perform_update(self, serializer):
        alvo = serializer.instance
        dados = serializer.validated_data
        quem = self.request.user

        if alvo.is_superuser and not quem.is_superuser:
            raise PermissionDenied('Só um superusuário pode alterar outro superusuário.')
        if 'is_superuser' in dados and dados['is_superuser'] != alvo.is_superuser and not quem.is_superuser:
            raise PermissionDenied('Só um superusuário pode conceder ou remover o papel de superusuário.')
        if alvo.pk == quem.pk and (dados.get('is_staff') is False or dados.get('is_active') is False):
            raise PermissionDenied('Você não pode remover o seu próprio acesso de administrador.')

        user = serializer.save()
        if not user.is_active:
            Token.objects.filter(user=user).delete()

    def destroy(self, request, *args, **kwargs):
        alvo = self.get_object()
        if alvo.pk == request.user.pk:
            return _erro('Você não pode excluir a sua própria conta.', status.HTTP_403_FORBIDDEN)
        if alvo.is_superuser and not request.user.is_superuser:
            return _erro('Só um superusuário pode excluir outro superusuário.', status.HTTP_403_FORBIDDEN)
        alvo.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['get'])
    def me(self, request):
        return Response({'success': True, 'user': UserSerializer(request.user).data})


# =========================
# DASHBOARD GERENCIAL
# =========================

FAIXAS_RESOLUCAO = [
    ('menos_1h', 0, 1),
    ('1_2h', 1, 2),
    ('2_4h', 2, 4),
    ('4_8h', 4, 8),
    ('8_12h', 8, 12),
    ('12_24h', 12, 24),
    ('mais_24h', 24, None),
]


def _tempos_resolucao(queryset):
    """Horas entre a abertura e o primeiro REALIZADO/CONCLUÍDO de cada chamado."""
    resolvidos = queryset.annotate(
        resolvido_em=Min('historico__data_criacao', filter=Q(historico__status__in=STATUS_RESOLVIDO))
    ).filter(resolvido_em__isnull=False).values_list('data_criacao', 'resolvido_em', 'data_sugerida')

    horas, no_prazo, com_prazo = [], 0, 0
    for criado, resolvido, sugerida in resolvidos:
        horas.append(max((resolvido - criado).total_seconds() / 3600, 0))
        if sugerida:
            com_prazo += 1
            no_prazo += resolvido <= sugerida
    return horas, no_prazo, com_prazo


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard_gerencial(request):
    """Indicadores. ?dias=N limita aos chamados abertos nos últimos N dias."""
    queryset = _chamados_visiveis(request.user)
    agora = timezone.now()

    dias = request.query_params.get('dias')
    if dias and str(dias).isdigit() and int(dias) > 0:
        queryset = queryset.filter(data_criacao__gte=agora - timedelta(days=int(dias)))

    contagem = dict(queryset.values_list('status').annotate(n=Count('id')).values_list('status', 'n'))
    por_status = {
        'aberto': contagem.get('ABERTO', 0),
        'aguardando': contagem.get('AGUARDANDO RESP', 0),
        'em_andamento': contagem.get('EM ANDAMENTO', 0),
        'realizado': contagem.get('REALIZADO', 0),
        'concluido': contagem.get('CONCLUÍDO', 0),
        'cancelado': contagem.get('CANCELADO', 0),
    }
    urg = dict(queryset.values_list('urgencia').annotate(n=Count('id')).values_list('urgencia', 'n'))
    por_urgencia = {
        'critico': urg.get('Crítico', 0),
        'alta': urg.get('Alta', 0),
        'media': urg.get('Média', 0),
        'baixa': urg.get('Baixa', 0),
    }

    criticos = queryset.filter(urgencia__in=['Crítico', 'Alta'], status__in=STATUS_EM_ABERTO)
    atrasados = queryset.filter(data_sugerida__lt=agora, status__in=STATUS_EM_ABERTO + ['REALIZADO']).count()

    horas, no_prazo, com_prazo = _tempos_resolucao(queryset)
    tempo_medio_horas = round(sum(horas) / len(horas), 1) if horas else None
    tempo_resolucao = {chave: 0 for chave, _, _ in FAIXAS_RESOLUCAO}
    for h in horas:
        for chave, minimo, maximo in FAIXAS_RESOLUCAO:
            if h >= minimo and (maximo is None or h < maximo):
                tempo_resolucao[chave] += 1
                break

    total = sum(por_status.values())
    resolvidos = por_status['realizado'] + por_status['concluido']
    base_taxa = total - por_status['cancelado']

    ativos = Ativo.objects.all()
    ativos_status = dict(ativos.values_list('status').annotate(n=Count('id')).values_list('status', 'n'))
    top_ativos = Ativo.objects.annotate(
        n=Count('chamados', filter=Q(chamados__in=queryset.values('pk')), distinct=True)
    ).filter(n__gt=0).order_by('-n', 'nome')[:5]

    return Response({
        'success': True,
        'data': {
            'kpis': {
                'total_chamados': total,
                'abertos': por_status['aberto'],
                'em_andamento': por_status['em_andamento'],
                'aguardando': por_status['aguardando'],
                'realizado': por_status['realizado'],
                'concluido': por_status['concluido'],
                'cancelado': por_status['cancelado'],
                'criticos_abertos': criticos.count(),
                'atrasados': atrasados,
                'tempo_medio': _formatar_horas(tempo_medio_horas),
                'tempo_medio_horas': tempo_medio_horas,
                'taxa_resolucao': round(100 * resolvidos / base_taxa) if base_taxa else 0,
                'no_prazo_percentual': round(100 * no_prazo / com_prazo) if com_prazo else None,
            },
            'por_status': por_status,
            'por_urgencia': por_urgencia,
            'periodo': {
                'ultimos_7_dias': queryset.filter(data_criacao__gte=agora - timedelta(days=7)).count(),
                'ultimos_30_dias': queryset.filter(data_criacao__gte=agora - timedelta(days=30)).count(),
                'ultimos_90_dias': queryset.filter(data_criacao__gte=agora - timedelta(days=90)).count(),
            },
            'tempo_resolucao': tempo_resolucao,
            'criticos': ChamadoReadSerializer(
                criticos.select_related('solicitante', 'ativo_ref').prefetch_related('responsaveis')[:10],
                many=True, context={'request': request},
            ).data,
            'ativos': {
                'total': sum(ativos_status.values()),
                'ativos': ativos_status.get('Ativo', 0),
                'manutencao': ativos_status.get('Manutenção', 0),
                'inativos': ativos_status.get('Inativo', 0),
                'mais_chamados': [
                    {'id': a.id, 'codigo': a.codigo, 'nome': a.nome, 'status': a.status, 'total_chamados': a.n}
                    for a in top_ativos
                ],
            },
        },
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
            'nome': user.get_full_name() or user.username,
            'is_staff': user.is_staff,
            'is_superuser': user.is_superuser,
            'date_joined': user.date_joined.strftime('%Y-%m-%d'),
        },
    })


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_user_profile(request):
    user = request.user
    data = request.data
    errors = {}

    if 'email' in data:
        email = str(data['email'] or '').strip().lower()
        if not VerificadorEmail.validar_sintaxe(email):
            errors['email'] = 'Informe um e-mail válido.'
        elif User.objects.filter(email__iexact=email).exclude(id=user.id).exists():
            errors['email'] = 'Este e-mail já está em uso.'
        else:
            # Quem se cadastrou pelo e-mail tem username = e-mail; mantém os dois iguais.
            if user.username.lower() == (user.email or '').lower() and \
                    not User.objects.filter(username__iexact=email).exclude(id=user.id).exists():
                user.username = email
            user.email = email

    if 'username' in data and str(data['username'] or '').strip() != user.username:
        username = str(data['username'] or '').strip()
        if len(username) < 3:
            errors['username'] = 'O usuário precisa ter pelo menos 3 caracteres.'
        elif User.objects.filter(username__iexact=username).exclude(id=user.id).exists():
            errors['username'] = 'Este nome de usuário já está em uso.'
        else:
            user.username = username

    if 'first_name' in data:
        first_name = str(data['first_name'] or '').strip()
        if not first_name:
            errors['first_name'] = 'O nome não pode ficar vazio.'
        else:
            user.first_name = first_name[:150]

    if 'last_name' in data:
        user.last_name = str(data['last_name'] or '').strip()[:150]

    if errors:
        return Response({'success': False, 'message': next(iter(errors.values())), 'errors': errors},
                        status=status.HTTP_400_BAD_REQUEST)

    user.save()
    return Response({
        'success': True,
        'message': 'Perfil atualizado com sucesso.',
        'data': UserSerializer(user).data,
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    user = request.user
    senha_atual = str(request.data.get('senha_atual') or '')
    nova_senha = str(request.data.get('nova_senha') or '')
    confirmar = str(request.data.get('confirmar_senha') or '')

    errors = {}
    if not senha_atual:
        errors['senha_atual'] = 'Informe a senha atual.'
    elif not user.check_password(senha_atual):
        errors['senha_atual'] = 'Senha atual incorreta.'
    if len(nova_senha) < 6:
        errors['nova_senha'] = 'A nova senha precisa ter pelo menos 6 caracteres.'
    if nova_senha != confirmar:
        errors['confirmar_senha'] = 'As senhas não conferem.'
    if errors:
        return Response({'success': False, 'message': next(iter(errors.values())), 'errors': errors},
                        status=status.HTTP_400_BAD_REQUEST)

    user.set_password(nova_senha)
    user.save(update_fields=['password'])
    Token.objects.filter(user=user).delete()
    novo = Token.objects.create(user=user)
    return Response({'success': True, 'message': 'Senha alterada com sucesso.', 'token': novo.key})


def _estatisticas_usuario(user):
    chamados = Chamado.objects.filter(
        pk__in=Chamado.objects.filter(Q(solicitante=user) | Q(responsaveis=user)).values('pk')
    )
    historico = ChamadoStatusHistory.objects.filter(usuario=user).select_related('chamado') \
        .order_by('-data_criacao')[:8]
    comentarios = Comentario.objects.filter(autor=user).select_related('chamado').order_by('-data_criacao')[:8]

    atividades = [
        {
            'tipo': 'status',
            'status': h.status,
            'texto': h.descricao,
            'chamado_id': h.chamado_id,
            'chamado_titulo': h.chamado.titulo,
            'data': h.data_criacao,
        }
        for h in historico
    ] + [
        {
            'tipo': 'comentario',
            'status': None,
            'texto': c.texto,
            'chamado_id': c.chamado_id,
            'chamado_titulo': c.chamado.titulo,
            'data': c.data_criacao,
        }
        for c in comentarios
    ]
    atividades.sort(key=lambda a: a['data'], reverse=True)

    return {
        'total_chamados': chamados.count(),
        'chamados_solicitados': Chamado.objects.filter(solicitante=user).count(),
        'chamados_responsavel': Chamado.objects.filter(responsaveis=user).count(),
        'chamados_ativos': chamados.filter(status__in=STATUS_EM_ABERTO + ['REALIZADO']).count(),
        'chamados_concluidos': chamados.filter(status='CONCLUÍDO').count(),
        'por_status': list(chamados.values('status').annotate(total=Count('id')).order_by('status')),
        'por_urgencia': list(chamados.values('urgencia').annotate(total=Count('id')).order_by('urgencia')),
        'atividades_recentes': atividades[:8],
    }


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_statistics(request):
    return Response({'success': True, 'data': _estatisticas_usuario(request.user)})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_statistics_by_id(request, user_id):
    if not request.user.is_staff and request.user.id != user_id:
        return _erro('Você não tem permissão para ver estas estatísticas.', status.HTTP_403_FORBIDDEN)
    user = User.objects.filter(id=user_id).first()
    if not user:
        return _erro('Usuário não encontrado.', status.HTTP_404_NOT_FOUND)
    return Response({'success': True, 'data': _estatisticas_usuario(user)})
