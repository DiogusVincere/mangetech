from django.db import models
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from django.utils import timezone
import secrets
import string

# ===========================================================
#               MODELOS DE CHAMADOS
# ===========================================================

class Chamado(models.Model):
    """Modelo principal de Chamado/Task"""
    
    STATUS_CHOICES = [
        ('ABERTO', 'Aberto'),
        ('AGUARDANDO RESP', 'Aguardando Responsáveis'),
        ('EM ANDAMENTO', 'Em Andamento'),
        ('REALIZADO', 'Realizado'),
        ('CONCLUÍDO', 'Concluído'),
        ('CANCELADO', 'Cancelado'),
    ]

    URGENCIA_CHOICES = [
        ('Crítico', 'Crítico'),
        ('Alta', 'Alta'),
        ('Média', 'Média'),
        ('Baixa', 'Baixa'),
    ]

    titulo = models.CharField(max_length=255, verbose_name="Título")
    descricao = models.TextField(verbose_name="Descrição")
    ativo = models.CharField(max_length=200, verbose_name="Ativo/Equipamento")
    ambiente = models.CharField(max_length=200, verbose_name="Ambiente", default="Não informado")
    
    solicitante = models.ForeignKey(
        User, related_name='chamados_solicitados', on_delete=models.SET_NULL,
        null=True, verbose_name="Solicitante"
    )
    
    responsaveis = models.ManyToManyField(
        User, related_name='chamados_responsaveis', blank=True, verbose_name="Responsáveis"
    )
    
    urgencia = models.CharField(
        max_length=20, choices=URGENCIA_CHOICES, default='Média',
        verbose_name="Nível de Urgência"
    )
    
    status = models.CharField(
        max_length=30, choices=STATUS_CHOICES, default='ABERTO',
        verbose_name="Status"
    )
    
    data_criacao = models.DateTimeField(auto_now_add=True, verbose_name="Data de Criação")
    data_sugerida = models.DateTimeField(null=True, blank=True, verbose_name="Data Sugerida")
    data_atualizacao = models.DateTimeField(auto_now=True, verbose_name="Última Atualização")

    class Meta:
        verbose_name = "Chamado"
        verbose_name_plural = "Chamados"
        ordering = ['-data_criacao']

    def __str__(self):
        return f"#{self.id} - {self.titulo}"

    def delete(self, *args, **kwargs):
        if self.status == 'EM ANDAMENTO':
            raise ValidationError("Não é possível excluir um chamado que está em andamento.")
        super().delete(*args, **kwargs)


class ChamadoStatusHistory(models.Model):
    """Histórico de alterações de status"""
    
    chamado = models.ForeignKey(
        Chamado, related_name='historico', on_delete=models.CASCADE
    )
    status = models.CharField(max_length=30)
    descricao = models.TextField(verbose_name="Descrição da Mudança")
    
    usuario = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, verbose_name="Usuário Responsável"
    )
    
    data_criacao = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Histórico de Status"
        verbose_name_plural = "Históricos de Status"
        ordering = ['-data_criacao']

    def __str__(self):
        return f"Histórico #{self.id} - Chamado #{self.chamado.id}"


class ChamadoStatusImage(models.Model):
    """Fotos anexadas ao histórico"""
    
    historico = models.ForeignKey(
        ChamadoStatusHistory, related_name='fotos', on_delete=models.CASCADE
    )
    imagem = models.ImageField(upload_to='chamados/historico/%Y/%m/%d/')
    data_upload = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Imagem do Histórico"
        verbose_name_plural = "Imagens do Histórico"

    def __str__(self):
        return f"Imagem {self.id} - Histórico #{self.historico.id}"


class ChamadoAnexo(models.Model):
    """Arquivos anexados ao chamado"""
    
    chamado = models.ForeignKey(
        Chamado, related_name='anexos', on_delete=models.CASCADE
    )
    arquivo = models.FileField(upload_to='chamados/anexos/%Y/%m/%d/')
    nome_original = models.CharField(max_length=255)
    data_upload = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Anexo"
        verbose_name_plural = "Anexos"

    def __str__(self):
        return f"Anexo {self.nome_original} - Chamado #{self.chamado.id}"


class Comentario(models.Model):
    """Comentários do chamado"""
    
    chamado = models.ForeignKey(
        Chamado, related_name='comentarios', on_delete=models.CASCADE
    )
    autor = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, verbose_name="Autor"
    )
    texto = models.TextField(verbose_name="Comentário")
    data_criacao = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Comentário"
        verbose_name_plural = "Comentários"
        ordering = ['-data_criacao']

    def __str__(self):
        return f"Comentário de {self.autor} em Chamado #{self.chamado.id}"
    
class ComentarioFoto(models.Model):
    """Fotos anexadas aos comentários"""
    
    comentario = models.ForeignKey(
        Comentario, related_name='fotos', on_delete=models.CASCADE
    )
    imagem = models.ImageField(upload_to='chamados/comentarios/%Y/%m/%d/')
    data_upload = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Foto do Comentário"
        verbose_name_plural = "Fotos dos Comentários"

    def __str__(self):
        return f"Foto {self.id} - Comentário #{self.comentario.id}"    


# ===========================================================
#               MODELOS DE ATIVOS
# ===========================================================

class Ativo(models.Model):
    """Cadastro de ativos/equipamentos"""
    
    STATUS_CHOICES = [
        ('Ativo', 'Ativo'),
        ('Inativo', 'Inativo'),
        ('Manutenção', 'Manutenção'),
    ]
    
    codigo = models.CharField(max_length=50, unique=True, verbose_name="Código/Tag QR")
    nome = models.CharField(max_length=200, verbose_name="Nome")
    modelo = models.CharField(max_length=200, verbose_name="Modelo")
    fabricante = models.CharField(max_length=200, blank=True, verbose_name="Fabricante")
    numero_serie = models.CharField(max_length=200, blank=True, verbose_name="Número de Série")
    fornecedor = models.CharField(max_length=200, blank=True, verbose_name="Fornecedor")

    ambiente = models.CharField(
        max_length=200, verbose_name="Ambiente/Localização", default="Não informado"
    )
    
    status = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default='Ativo',
        verbose_name="Status"
    )
    
    data_cadastro = models.DateTimeField(auto_now_add=True)
    data_atualizacao = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Ativo"
        verbose_name_plural = "Ativos"
        ordering = ['nome']

    def __str__(self):
        return f"{self.codigo} - {self.nome}"


class AtivoHistorico(models.Model):
    """Histórico de movimentações do ativo"""
    
    ativo = models.ForeignKey(
        Ativo, related_name='historico_movimentacoes', on_delete=models.CASCADE
    )
    tipo = models.CharField(max_length=100, verbose_name="Tipo de Movimentação")
    descricao = models.TextField(verbose_name="Descrição")
    usuario = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, verbose_name="Responsável"
    )
    data_criacao = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Histórico do Ativo"
        verbose_name_plural = "Históricos dos Ativos"
        ordering = ['-data_criacao']

    def __str__(self):
        return f"{self.tipo} - {self.ativo.codigo}"


# ===========================================================
#             TOKEN DE RECUPERAÇÃO DE SENHA
# ===========================================================

class TokenRecuperacaoSenha(models.Model):
    """Token de 6 dígitos para recuperação de senha"""

    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name='token_recuperacao'
    )
    
    token = models.CharField(max_length=6, unique=True)
    email_enviado_para = models.EmailField()
    
    tentativas = models.IntegerField(default=0)
    max_tentativas = 5

    criado_em = models.DateTimeField(auto_now_add=True)
    expira_em = models.DateTimeField()
    usado_em = models.DateTimeField(null=True, blank=True)

    ativo = models.BooleanField(default=True)

    class Meta:
        verbose_name = "Token de Recuperação de Senha"
        verbose_name_plural = "Tokens de Recuperação de Senha"

    def __str__(self):
        return f"Token para {self.user.email}"

    @staticmethod
    def gerar_token():
        """Gera um token numérico de 6 dígitos"""
        return ''.join(secrets.choice(string.digits) for _ in range(6))

    @staticmethod
    def criar_para_usuario(user: User, email: str):
        """Cria novo token para o usuário"""
        from datetime import timedelta
        
        TokenRecuperacaoSenha.objects.filter(user=user).delete()

        token_str = TokenRecuperacaoSenha.gerar_token()

        return TokenRecuperacaoSenha.objects.create(
            user=user,
            token=token_str,
            email_enviado_para=email,
            expira_em=timezone.now() + timedelta(minutes=15),
            ativo=True
        )

    def is_valido(self):
        """Verifica se o token ainda é válido"""
        if not self.ativo:
            return False
        if self.usado_em:
            return False
        if self.tentativas >= self.max_tentativas:
            return False
        if timezone.now() > self.expira_em:
            return False
        return True

    def verificar_token(self, token_fornecido: str):
        """Verifica se o token fornecido está correto"""
        if not self.is_valido():
            return False
        
        if self.token != token_fornecido:
            self.tentativas += 1
            self.save()
            return False
        
        self.usado_em = timezone.now()
        self.ativo = False
        self.save()
        return True

    def marcar_como_usado(self):
        """Marca token como utilizado"""
        self.usado_em = timezone.now()
        self.ativo = False
        self.save()


# ===========================================================
#                    VERIFICAÇÃO DE EMAIL
# ===========================================================

class VerificacaoEmail(models.Model):
    """Verificação de emails reais antes de uso"""
    
    STATUS_CHOICES = [
        ('PENDENTE', 'Pendente'),
        ('VERIFICADO', 'Verificado'),
        ('REJEITADO', 'Rejeitado'),
        ('BLOQUEADO', 'Bloqueado'),
    ]
    
    email = models.EmailField(unique=True, db_index=True, verbose_name="Email")
    status = models.CharField(
        max_length=15, choices=STATUS_CHOICES, default='PENDENTE',
        verbose_name="Status"
    )

    dominio_valido = models.BooleanField(default=False, verbose_name="Domínio Válido")
    email_real = models.BooleanField(default=False, verbose_name="Email Real")

    tentativas_verificacao = models.IntegerField(default=0, verbose_name="Tentativas")

    criado_em = models.DateTimeField(auto_now_add=True, verbose_name="Criado em")
    verificado_em = models.DateTimeField(null=True, blank=True, verbose_name="Verificado em")

    class Meta:
        verbose_name = "Verificação de Email"
        verbose_name_plural = "Verificações de Email"
        ordering = ['-criado_em']

    def __str__(self):
        return f"{self.email} - {self.status}"

    def marcar_como_verificado(self):
        """Marca email como verificado"""
        self.status = 'VERIFICADO'
        self.email_real = True
        self.verificado_em = timezone.now()
        self.save()

    def marcar_como_rejeitado(self):
        """Marca email como rejeitado"""
        self.status = 'REJEITADO'
        self.email_real = False
        self.save()
        