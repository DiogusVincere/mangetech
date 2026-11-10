from django.contrib.auth.models import User
from rest_framework import serializers

from .models import (
    Ativo,
    AtivoHistorico,
    Chamado,
    ChamadoAnexo,
    ChamadoStatusHistory,
    ChamadoStatusImage,
    Comentario,
    ComentarioFoto,
)

STATUS_EM_ABERTO = ['ABERTO', 'AGUARDANDO RESP', 'EM ANDAMENTO']

# Limites dos uploads (fotos e anexos).
TAMANHO_MAX_FOTO = 10 * 1024 * 1024
TAMANHO_MAX_ANEXO = 20 * 1024 * 1024


def _url_absoluta(serializer, arquivo):
    if not arquivo:
        return None
    request = serializer.context.get('request')
    return request.build_absolute_uri(arquivo.url) if request else arquivo.url


def _nome_usuario(user, padrao='Sistema'):
    if not user:
        return padrao
    return user.get_full_name() or user.username


class FotoField(serializers.ImageField):
    """ImageField com limite de tamanho."""

    def to_internal_value(self, data):
        arquivo = super().to_internal_value(data)
        if arquivo.size > TAMANHO_MAX_FOTO:
            raise serializers.ValidationError('Cada foto pode ter no máximo 10 MB.')
        return arquivo


# ========== USUÁRIOS ==========

class UserSerializer(serializers.ModelSerializer):
    """Dados do usuário. is_staff/is_superuser/is_active só mudam por admin
    (a view de usuários exige IsAdminUser para escrita)."""

    nome = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id',
            'username',
            'email',
            'first_name',
            'last_name',
            'nome',
            'is_staff',
            'is_superuser',
            'is_active',
            'date_joined',
            'last_login',
        ]
        read_only_fields = ['id', 'date_joined', 'last_login']

    def get_nome(self, obj):
        return _nome_usuario(obj, obj.username)

    def validate_email(self, value):
        value = (value or '').strip().lower()
        qs = User.objects.filter(email__iexact=value)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        if value and qs.exists():
            raise serializers.ValidationError('Este e-mail já está em uso.')
        return value


# ========== CHAMADOS ==========

class ChamadoStatusImageSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()

    class Meta:
        model = ChamadoStatusImage
        fields = ['id', 'imagem', 'url', 'data_upload']

    def get_url(self, obj):
        return _url_absoluta(self, obj.imagem)


class ChamadoStatusHistorySerializer(serializers.ModelSerializer):
    usuario_nome = serializers.SerializerMethodField()
    fotos = ChamadoStatusImageSerializer(many=True, read_only=True)
    timestamp = serializers.DateTimeField(source='data_criacao', read_only=True)

    class Meta:
        model = ChamadoStatusHistory
        fields = ['id', 'status', 'descricao', 'usuario', 'usuario_nome', 'timestamp', 'data_criacao', 'fotos']

    def get_usuario_nome(self, obj):
        return _nome_usuario(obj.usuario)


class ChamadoAnexoSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()

    class Meta:
        model = ChamadoAnexo
        fields = ['id', 'arquivo', 'url', 'nome_original', 'data_upload']

    def get_url(self, obj):
        return _url_absoluta(self, obj.arquivo)


class ComentarioFotoSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()

    class Meta:
        model = ComentarioFoto
        fields = ['id', 'imagem', 'url', 'data_upload']

    def get_url(self, obj):
        return _url_absoluta(self, obj.imagem)


class ComentarioSerializer(serializers.ModelSerializer):
    usuario_nome = serializers.SerializerMethodField()
    timestamp = serializers.DateTimeField(source='data_criacao', read_only=True)
    fotos = ComentarioFotoSerializer(many=True, read_only=True)

    class Meta:
        model = Comentario
        fields = ['id', 'chamado', 'autor', 'usuario_nome', 'texto', 'timestamp', 'data_criacao', 'fotos']
        read_only_fields = ['autor', 'data_criacao']

    def get_usuario_nome(self, obj):
        return _nome_usuario(obj.autor, 'Anônimo')


class AtivoResumoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ativo
        fields = ['id', 'codigo', 'nome', 'ambiente', 'status']


class ChamadoReadSerializer(serializers.ModelSerializer):
    """Leitura detalhada. O id sai como texto (contrato antigo do front e do app)."""

    id = serializers.SerializerMethodField()
    solicitante_nome = serializers.SerializerMethodField()
    solicitante_email = serializers.SerializerMethodField()
    responsaveis_detalhes = UserSerializer(source='responsaveis', many=True, read_only=True)
    responsaveis_nomes = serializers.SerializerMethodField()
    ativo_detalhes = AtivoResumoSerializer(source='ativo_ref', read_only=True)

    historico = ChamadoStatusHistorySerializer(many=True, read_only=True)
    comentarios = ComentarioSerializer(many=True, read_only=True)
    anexos_detalhes = ChamadoAnexoSerializer(source='anexos', many=True, read_only=True)

    prioridade = serializers.CharField(source='urgencia', read_only=True)
    data_criacao_formatada = serializers.SerializerMethodField()
    data_sugerida_formatada = serializers.SerializerMethodField()
    atrasado = serializers.SerializerMethodField()

    class Meta:
        model = Chamado
        fields = [
            'id',
            'titulo',
            'descricao',
            'ativo',
            'ativo_ref',
            'ativo_detalhes',
            'ambiente',
            'solicitante',
            'solicitante_nome',
            'solicitante_email',
            'responsaveis',
            'responsaveis_detalhes',
            'responsaveis_nomes',
            'urgencia',
            'prioridade',
            'status',
            'data_criacao',
            'data_criacao_formatada',
            'data_sugerida',
            'data_sugerida_formatada',
            'data_atualizacao',
            'atrasado',
            'historico',
            'comentarios',
            'anexos_detalhes',
        ]

    def get_id(self, obj):
        return str(obj.id)

    def get_solicitante_nome(self, obj):
        return _nome_usuario(obj.solicitante, None)

    def get_solicitante_email(self, obj):
        return obj.solicitante.email if obj.solicitante else None

    def get_responsaveis_nomes(self, obj):
        return [_nome_usuario(r) for r in obj.responsaveis.all()]

    def get_data_criacao_formatada(self, obj):
        from django.utils import timezone
        return timezone.localtime(obj.data_criacao).strftime('%d/%m/%Y %H:%M')

    def get_data_sugerida_formatada(self, obj):
        if not obj.data_sugerida:
            return None
        from django.utils import timezone
        return timezone.localtime(obj.data_sugerida).strftime('%d/%m/%Y %H:%M')

    def get_atrasado(self, obj):
        from django.utils import timezone
        return bool(
            obj.data_sugerida
            and obj.data_sugerida < timezone.now()
            and obj.status in STATUS_EM_ABERTO + ['REALIZADO']
        )


class ChamadoWriteSerializer(serializers.ModelSerializer):
    """Criação/edição. Aceita o ativo como texto (`ativo`) e/ou pelo id (`ativo_ref`)."""

    class Meta:
        model = Chamado
        fields = [
            'id',
            'titulo',
            'descricao',
            'ativo',
            'ativo_ref',
            'ambiente',
            'responsaveis',
            'urgencia',
            'status',
            'data_sugerida',
        ]
        extra_kwargs = {
            'ativo': {'required': False, 'allow_blank': True},
            'ambiente': {'required': False, 'allow_blank': True},
            'status': {'required': False},
        }

    def validate(self, attrs):
        ativo_txt = attrs.get('ativo', getattr(self.instance, 'ativo', ''))
        ativo_ref = attrs.get('ativo_ref', getattr(self.instance, 'ativo_ref', None))
        if not (ativo_txt or '').strip() and not ativo_ref:
            raise serializers.ValidationError({'ativo': 'Informe o ativo/equipamento.'})
        # Trocou o ativo pelo id sem mandar texto: o texto acompanha o novo ativo.
        if 'ativo_ref' in attrs and attrs['ativo_ref'] and 'ativo' not in attrs:
            attrs['ativo'] = f"{attrs['ativo_ref'].codigo} - {attrs['ativo_ref'].nome}"
        # Trocou só o texto: refaz o vínculo a partir dele.
        if 'ativo' in attrs and 'ativo_ref' not in attrs:
            attrs['ativo_ref'] = Ativo.buscar_por_texto(attrs['ativo'])
        if 'ambiente' in attrs or not self.instance:
            ambiente = (attrs.get('ambiente') or '').strip()
            if not ambiente:
                ativo = attrs.get('ativo_ref') or getattr(self.instance, 'ativo_ref', None)
                ambiente = ativo.ambiente if ativo else 'Não informado'
            attrs['ambiente'] = ambiente
        return attrs

    def to_representation(self, instance):
        return ChamadoReadSerializer(instance, context=self.context).data


class MudarStatusSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Chamado.STATUS_CHOICES)
    descricao = serializers.CharField(min_length=10, error_messages={
        'min_length': 'A descrição precisa ter pelo menos 10 caracteres.',
    })
    fotos = serializers.ListField(child=FotoField(), required=False, allow_empty=True, max_length=10)


class CriarComentarioSerializer(serializers.Serializer):
    texto = serializers.CharField(min_length=1, trim_whitespace=True)
    fotos = serializers.ListField(child=FotoField(), required=False, allow_empty=True, max_length=10)

    def create(self, validated_data):
        fotos = validated_data.pop('fotos', [])
        comentario = Comentario.objects.create(
            chamado=validated_data['chamado'],
            autor=validated_data['autor'],
            texto=validated_data['texto'],
        )
        for foto in fotos:
            ComentarioFoto.objects.create(comentario=comentario, imagem=foto)
        return comentario


# ========== ATIVOS ==========

class AtivoHistoricoSerializer(serializers.ModelSerializer):
    usuario_nome = serializers.SerializerMethodField()

    class Meta:
        model = AtivoHistorico
        fields = ['id', 'tipo', 'descricao', 'usuario', 'usuario_nome', 'data_criacao']

    def get_usuario_nome(self, obj):
        return _nome_usuario(obj.usuario)


class AtivoSerializer(serializers.ModelSerializer):
    historico_movimentacoes = AtivoHistoricoSerializer(many=True, read_only=True)
    total_chamados = serializers.SerializerMethodField()
    chamados_abertos = serializers.SerializerMethodField()
    ultimo_chamado = serializers.SerializerMethodField()
    garantia_ate = serializers.DateField(read_only=True)
    em_garantia = serializers.SerializerMethodField()

    class Meta:
        model = Ativo
        fields = [
            'id',
            'codigo',
            'nome',
            'modelo',
            'fabricante',
            'numero_serie',
            'fornecedor',
            'ambiente',
            'status',
            'data_aquisicao',
            'valor',
            'garantia_meses',
            'garantia_ate',
            'em_garantia',
            'observacoes',
            'data_cadastro',
            'data_atualizacao',
            'historico_movimentacoes',
            'total_chamados',
            'chamados_abertos',
            'ultimo_chamado',
        ]
        extra_kwargs = {
            'modelo': {'required': False, 'allow_blank': True},
            # A unicidade (sem diferenciar maiúsculas) é checada em validate_codigo.
            'codigo': {'validators': []},
        }

    def validate_codigo(self, value):
        value = (value or '').strip()
        if not value:
            raise serializers.ValidationError('Informe o código do ativo.')
        if '/' in value:
            raise serializers.ValidationError('O código não pode ter barra (/).')
        qs = Ativo.objects.filter(codigo__iexact=value)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        if qs.exists():
            raise serializers.ValidationError('Já existe um ativo com este código.')
        return value

    def get_total_chamados(self, obj):
        anotado = getattr(obj, 'n_chamados', None)
        return anotado if anotado is not None else obj.chamados.count()

    def get_chamados_abertos(self, obj):
        anotado = getattr(obj, 'n_chamados_abertos', None)
        if anotado is not None:
            return anotado
        return obj.chamados.filter(status__in=STATUS_EM_ABERTO).count()

    def get_ultimo_chamado(self, obj):
        ultimo = obj.chamados.order_by('-data_criacao').first()
        if not ultimo:
            return None
        return {
            'id': str(ultimo.id),
            'titulo': ultimo.titulo,
            'status': ultimo.status,
            'data': ultimo.data_criacao.strftime('%d/%m/%Y'),
        }

    def get_em_garantia(self, obj):
        fim = obj.garantia_ate
        if not fim:
            return None
        from django.utils import timezone
        return fim >= timezone.localdate()


# ========== AUTENTICAÇÃO ==========

class UserRegistrationSerializer(serializers.Serializer):
    nome = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    senha = serializers.CharField(min_length=6, write_only=True, error_messages={
        'min_length': 'A senha precisa ter pelo menos 6 caracteres.',
    })

    def validate_email(self, value):
        value = value.strip().lower()
        if User.objects.filter(email__iexact=value).exists() or User.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError('Este e-mail já está cadastrado.')
        return value

    def validate_nome(self, value):
        value = ' '.join(value.split())
        if len(value) < 2:
            raise serializers.ValidationError('Informe seu nome.')
        return value

    def create(self, validated_data):
        partes = validated_data['nome'].split(' ', 1)
        return User.objects.create_user(
            username=validated_data['email'],
            email=validated_data['email'],
            password=validated_data['senha'],
            first_name=partes[0][:150],
            last_name=(partes[1] if len(partes) > 1 else '')[:150],
        )


class UserLoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    senha = serializers.CharField(write_only=True)
