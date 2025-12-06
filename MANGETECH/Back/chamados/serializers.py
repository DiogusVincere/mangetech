from rest_framework import serializers
from django.contrib.auth.models import User
from .models import (
    Chamado, 
    ChamadoStatusHistory, 
    ChamadoStatusImage,
    ChamadoAnexo,
    Comentario,
    ComentarioFoto,
    Ativo,
    AtivoHistorico
    
)


class UserSerializer(serializers.ModelSerializer):
    """Serializer para dados básicos do usuário"""
    
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
            'date_joined'  
        ]    

    def get_nome(self, obj):
        return obj.get_full_name() or obj.username


class ChamadoStatusImageSerializer(serializers.ModelSerializer):
    """Serializer para imagens do histórico"""
    
    url = serializers.SerializerMethodField()
    
    class Meta:
        model = ChamadoStatusImage
        fields = ['id', 'imagem', 'url', 'data_upload']
    
    def get_url(self, obj):
        if obj.imagem:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.imagem.url)
        return None


class ChamadoStatusHistorySerializer(serializers.ModelSerializer):
    """Serializer para histórico de status"""
    
    usuario_nome = serializers.SerializerMethodField()
    fotos = ChamadoStatusImageSerializer(many=True, read_only=True)
    timestamp = serializers.DateTimeField(source='data_criacao')
    
    class Meta:
        model = ChamadoStatusHistory
        fields = [
            'id', 
            'status', 
            'descricao', 
            'usuario', 
            'usuario_nome',
            'timestamp',
            'data_criacao',
            'fotos'
        ]
    
    def get_usuario_nome(self, obj):
        if obj.usuario:
            return obj.usuario.get_full_name() or obj.usuario.username
        return "Sistema"


class ChamadoAnexoSerializer(serializers.ModelSerializer):
    """Serializer para anexos do chamado"""
    
    url = serializers.SerializerMethodField()
    
    class Meta:
        model = ChamadoAnexo
        fields = ['id', 'arquivo', 'url', 'nome_original', 'data_upload']
    
    def get_url(self, obj):
        if obj.arquivo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.arquivo.url)
        return None

class ComentarioFotoSerializer(serializers.ModelSerializer):
    """Serializer para fotos dos comentários"""
    
    url = serializers.SerializerMethodField()
    
    class Meta:
        model = ComentarioFoto  # Você precisa criar este modelo
        fields = ['id', 'imagem', 'url', 'data_upload']
    
    def get_url(self, obj):
        if obj.imagem:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.imagem.url)
        return None

class ComentarioSerializer(serializers.ModelSerializer):
    """Serializer para comentários"""
    
    usuario_nome = serializers.SerializerMethodField()
    timestamp = serializers.DateTimeField(source='data_criacao')
    fotos = ComentarioFotoSerializer(many=True, read_only=True)  
    
    class Meta:
        model = Comentario
        fields = [
            'id',
            'chamado',
            'autor',
            'usuario_nome',
            'texto',
            'timestamp',
            'data_criacao',
            'fotos' 
        ]
    
    def get_usuario_nome(self, obj):
        if obj.autor:
            return obj.autor.get_full_name() or obj.autor.username
        return "Anônimo"


# ========== SERIALIZERS PARA LEITURA (READ) ==========

class ChamadoReadSerializer(serializers.ModelSerializer):

    """Serializer detalhado para leitura de chamados"""
    
    # Usuários
    id = serializers.SerializerMethodField()
    solicitante_nome = serializers.SerializerMethodField()
    solicitante_email = serializers.SerializerMethodField()
    responsaveis_detalhes = UserSerializer(source='responsaveis', many=True, read_only=True)
    responsaveis_nomes = serializers.SerializerMethodField()
    
    # Relacionamentos
    historico = ChamadoStatusHistorySerializer(many=True, read_only=True)
    comentarios = ComentarioSerializer(many=True, read_only=True)
    anexos_detalhes = ChamadoAnexoSerializer(source='anexos', many=True, read_only=True)
    
    # Campos formatados
    prioridade = serializers.CharField(source='urgencia')
    data_criacao_formatada = serializers.SerializerMethodField()
    data_sugerida_formatada = serializers.SerializerMethodField()
    
    class Meta:
        model = Chamado
        fields = [
            'id',
            'titulo',
            'descricao',
            'ativo',
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
            'historico',
            'comentarios',
            'anexos_detalhes',
        ]

    def get_id(self, obj):
        return str(obj.id)

    def get_solicitante_nome(self, obj):
        if obj.solicitante:
            return obj.solicitante.get_full_name() or obj.solicitante.username
        return None
    
    def get_solicitante_email(self, obj):
        return obj.solicitante.email if obj.solicitante else None
    
    def get_responsaveis_nomes(self, obj):
        return [r.get_full_name() or r.username for r in obj.responsaveis.all()]
    
    def get_data_criacao_formatada(self, obj):
        return obj.data_criacao.strftime('%d/%m/%Y %H:%M')
    
    def get_data_sugerida_formatada(self, obj):
        if obj.data_sugerida:
            return obj.data_sugerida.strftime('%d/%m/%Y %H:%M')
        return None


# ========== SERIALIZERS PARA ESCRITA (WRITE) ==========

class ChamadoWriteSerializer(serializers.ModelSerializer):
    """Serializer simplificado para criação/atualização de chamados"""
    id = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Chamado
        fields = [
            'id',
            'titulo',
            'descricao',
            'ativo',
            'ambiente',
            'solicitante',
            'responsaveis',
            'urgencia',
            'status',
            'data_sugerida',
        ]
    def get_id(self, obj):
        return str(obj.id)

    def to_representation(self, instance):
        """Retorna com ReadSerializer que tem ID como string"""
        return ChamadoReadSerializer(instance, context=self.context).data
    
    def create(self, validated_data):
        responsaveis = validated_data.pop('responsaveis', [])
        chamado = Chamado.objects.create(**validated_data)
        chamado.responsaveis.set(responsaveis)
        
        # Criar histórico inicial
        ChamadoStatusHistory.objects.create(
            chamado=chamado,
            status=chamado.status,
            descricao=f"Chamado criado: {chamado.titulo}",
            usuario=chamado.solicitante
        )
        
        return chamado


class MudarStatusSerializer(serializers.Serializer):
    """Serializer para mudança de status"""
    
    status = serializers.ChoiceField(choices=Chamado.STATUS_CHOICES)
    descricao = serializers.CharField(min_length=10)
    fotos = serializers.ListField(
        child=serializers.ImageField(),
        required=False,
        allow_empty=True
    )


class CriarComentarioSerializer(serializers.Serializer):
    """Serializer para criar comentário"""
    
    texto = serializers.CharField(min_length=1)
    fotos = serializers.ListField(  # ADICIONAR
        child=serializers.ImageField(),
        required=False,
        allow_empty=True
    )
    
    def create(self, validated_data):
        chamado = validated_data.pop('chamado')
        autor = validated_data.pop('autor')
        fotos = validated_data.pop('fotos', [])  
        
        comentario = Comentario.objects.create(
            chamado=chamado,
            autor=autor,
            texto=validated_data['texto']
        )
        
        
        for foto in fotos:
            ComentarioFoto.objects.create(
                comentario=comentario,
                imagem=foto
            )
        
        return comentario


# ========== SERIALIZERS PARA ATIVOS ==========

class AtivoHistoricoSerializer(serializers.ModelSerializer):
    """Serializer para histórico de ativos"""
    
    usuario_nome = serializers.SerializerMethodField()
    
    class Meta:
        model = AtivoHistorico
        fields = [
            'id',
            'tipo',
            'descricao',
            'usuario',
            'usuario_nome',
            'data_criacao'
        ]
    
    def get_usuario_nome(self, obj):
        if obj.usuario:
            return obj.usuario.get_full_name() or obj.usuario.username
        return "Sistema"


class AtivoSerializer(serializers.ModelSerializer):
    """Serializer para ativos/equipamentos"""
    
    historico_movimentacoes = AtivoHistoricoSerializer(many=True, read_only=True)
    total_chamados = serializers.SerializerMethodField()
    chamados_abertos = serializers.SerializerMethodField()
    ultimo_chamado = serializers.SerializerMethodField()
    
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
            'data_cadastro',
            'data_atualizacao',
            'historico_movimentacoes',
            'total_chamados',
            'chamados_abertos',
            'ultimo_chamado'
        ]
    
    def get_total_chamados(self, obj):
        return Chamado.objects.filter(ativo__icontains=obj.codigo).count()
    
    def get_chamados_abertos(self, obj):
        return Chamado.objects.filter(
            ativo__icontains=obj.codigo,
            status__in=['ABERTO', 'EM ANDAMENTO', 'AGUARDANDO RESP']
        ).count()
    
    def get_ultimo_chamado(self, obj):
        ultimo = Chamado.objects.filter(
            ativo__icontains=obj.codigo
        ).order_by('-data_criacao').first()
        
        if ultimo:
            return {
                'id': str(ultimo.id),  
                'titulo': ultimo.titulo,
                'status': ultimo.status,
                'data': ultimo.data_criacao.strftime('%d/%m/%Y')
            }
        
        return None
    


# ========== SERIALIZERS PARA AUTENTICAÇÃO ==========

class UserRegistrationSerializer(serializers.Serializer):
    """Serializer para cadastro de usuário"""
    
    nome = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    senha = serializers.CharField(min_length=6, write_only=True)
    
    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Este email já está cadastrado.")
        return value
    
    def create(self, validated_data):
        nome_completo = validated_data['nome'].strip().split(' ', 1)
        first_name = nome_completo[0]
        last_name = nome_completo[1] if len(nome_completo) > 1 else ''
        
        user = User.objects.create_user(
            username=validated_data['email'],
            email=validated_data['email'],
            password=validated_data['senha'],
            first_name=first_name,
            last_name=last_name
        )
        return user


class UserLoginSerializer(serializers.Serializer):
    """Serializer para login"""
    
    email = serializers.EmailField()
    senha = serializers.CharField(write_only=True)
    
class UserSerializer(serializers.ModelSerializer):
    """Serializer para dados básicos do usuário"""
    
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
            'is_active'      
        ]
    
    def get_nome(self, obj):
        return obj.get_full_name() or obj.username