"""
Dados de demonstração do MangeTech.

    python manage.py seed_demo

Cria dois usuários, quatro ativos e seis chamados com histórico e comentários,
coerentes com os modelos de chamados/models.py. Pode rodar quantas vezes
quiser: procura por e-mail/username, código do ativo e título do chamado e só
cria o que falta. A senha dos usuários é pública de propósito e é reposta a
cada execução, para o login de demonstração nunca parar de funcionar.
"""

from datetime import timedelta

from django.contrib.auth.models import User
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from chamados.models import (
    Ativo,
    AtivoHistorico,
    Chamado,
    ChamadoStatusHistory,
    Comentario,
)

SENHA_DEMO = 'demo1234'

USUARIOS = [
    # username, e-mail (o login é feito pelo e-mail), nome, sobrenome, staff
    ('demo', 'demo@mangetech.local', 'Usuário', 'Demo', True),
    ('tecnico', 'tecnico@mangetech.local', 'Técnico', 'de Manutenção', False),
]

ATIVOS = [
    dict(
        codigo='AST-001', nome='Compressor de ar parafuso', modelo='GA 22',
        fabricante='Atlas Copco', numero_serie='AC-22-2019-0417',
        fornecedor='Atlas Copco Brasil', ambiente='Sala de compressores', status='Ativo',
    ),
    dict(
        codigo='AST-002', nome='Empilhadeira elétrica', modelo='RX 20-16',
        fabricante='Still', numero_serie='ST-516-2021-0088',
        fornecedor='Still Brasil', ambiente='Expedição', status='Manutenção',
    ),
    dict(
        codigo='AST-003', nome='Torno CNC', modelo='GL 240M',
        fabricante='Romi', numero_serie='RM-240-2018-1193',
        fornecedor='Romi', ambiente='Usinagem', status='Ativo',
    ),
    dict(
        codigo='AST-004', nome='Ar-condicionado split', modelo='36.000 BTU',
        fabricante='Carrier', numero_serie='CR-36-2017-2231',
        fornecedor='Friotec Climatização', ambiente='Sala de reuniões', status='Inativo',
    ),
]

# O campo "ativo" do chamado é texto livre; o código do ativo fica dentro dele
# porque a API relaciona chamado e ativo por `ativo__icontains=codigo`.
# Status e urgência seguem exatamente as escolhas do modelo.
CHAMADOS = [
    dict(
        titulo='Compressor desarmando por alta temperatura',
        descricao=(
            'O compressor AST-001 desarma depois de uns 20 minutos ligado, com '
            'alarme de temperatura do óleo. A linha de pintura fica sem ar comprimido.'
        ),
        ativo='AST-001 - Compressor de ar parafuso',
        ambiente='Sala de compressores',
        urgencia='Crítico',
        status='EM ANDAMENTO',
        dias_atras=2,
        sugerida_em_dias=0,
        responsaveis=['tecnico'],
        historico=[
            ('ABERTO', 'Chamado criado: Compressor desarmando por alta temperatura', 'demo'),
            ('AGUARDANDO RESP', 'Encaminhado para a manutenção mecânica.', 'demo'),
            ('EM ANDAMENTO', 'Técnico em campo. Radiador do óleo com sujeira; limpeza iniciada.', 'tecnico'),
        ],
        comentarios=[
            ('tecnico', 'Trocador de calor estava obstruído. Vou limpar e testar por uma hora antes de liberar.'),
            ('demo', 'Ok. Avise quando a linha de pintura puder voltar.'),
        ],
    ),
    dict(
        titulo='Empilhadeira com bateria que não segura carga',
        descricao=(
            'A empilhadeira AST-002 sai da carga completa e em menos de duas horas '
            'já indica bateria baixa. Precisa de avaliação da bateria e do carregador.'
        ),
        ativo='AST-002 - Empilhadeira elétrica',
        ambiente='Expedição',
        urgencia='Alta',
        status='AGUARDANDO RESP',
        dias_atras=1,
        sugerida_em_dias=2,
        responsaveis=[],
        historico=[
            ('ABERTO', 'Chamado criado: Empilhadeira com bateria que não segura carga', 'demo'),
            ('AGUARDANDO RESP', 'Aguardando orçamento do fornecedor para a bateria.', 'demo'),
        ],
        comentarios=[
            ('demo', 'Enquanto isso a expedição está usando a empilhadeira manual.'),
        ],
    ),
    dict(
        titulo='Troca de óleo e filtros do torno CNC (preventiva)',
        descricao=(
            'Manutenção preventiva programada do torno AST-003: troca do óleo '
            'hidráulico, filtros e verificação do nível do lubrificante das guias.'
        ),
        ativo='AST-003 - Torno CNC',
        ambiente='Usinagem',
        urgencia='Média',
        status='ABERTO',
        dias_atras=0,
        sugerida_em_dias=7,
        responsaveis=['tecnico'],
        historico=[
            ('ABERTO', 'Chamado criado: Troca de óleo e filtros do torno CNC (preventiva)', 'demo'),
        ],
        comentarios=[],
    ),
    dict(
        titulo='Ruído anormal no cabeçote do torno',
        descricao=(
            'Operador relatou ruído metálico no cabeçote do torno AST-003 em '
            'rotações acima de 2.000 rpm. Máquina parada por segurança.'
        ),
        ativo='AST-003 - Torno CNC',
        ambiente='Usinagem',
        urgencia='Alta',
        status='REALIZADO',
        dias_atras=6,
        sugerida_em_dias=None,
        responsaveis=['tecnico'],
        historico=[
            ('ABERTO', 'Chamado criado: Ruído anormal no cabeçote do torno', 'demo'),
            ('EM ANDAMENTO', 'Rolamento do eixo-árvore com folga.', 'tecnico'),
            ('REALIZADO', 'Rolamento trocado; aguardando validação do operador.', 'tecnico'),
        ],
        comentarios=[
            ('tecnico', 'Peça original, com nota fiscal anexada ao chamado.'),
        ],
    ),
    dict(
        titulo='Ar-condicionado da sala de reuniões não liga',
        descricao='O split AST-004 não responde ao controle nem ao botão do aparelho.',
        ativo='AST-004 - Ar-condicionado split',
        ambiente='Sala de reuniões',
        urgencia='Baixa',
        status='CONCLUÍDO',
        dias_atras=20,
        sugerida_em_dias=None,
        responsaveis=['tecnico'],
        historico=[
            ('ABERTO', 'Chamado criado: Ar-condicionado da sala de reuniões não liga', 'demo'),
            ('EM ANDAMENTO', 'Verificação do disjuntor e da placa eletrônica.', 'tecnico'),
            ('REALIZADO', 'Placa substituída; equipamento testado por 30 minutos.', 'tecnico'),
            ('CONCLUÍDO', 'Solicitante confirmou o funcionamento.', 'demo'),
        ],
        comentarios=[
            ('tecnico', 'Placa queimada por oscilação de energia. Sugiro um protetor na tomada.'),
        ],
    ),
    dict(
        titulo='Vazamento de ar na linha do compressor',
        descricao='Assobio constante perto do engate rápido da linha de ar da sala de compressores.',
        ativo='AST-001 - Compressor de ar parafuso',
        ambiente='Sala de compressores',
        urgencia='Média',
        status='CANCELADO',
        dias_atras=10,
        sugerida_em_dias=None,
        responsaveis=[],
        historico=[
            ('ABERTO', 'Chamado criado: Vazamento de ar na linha do compressor', 'demo'),
            ('CANCELADO', 'Era um engate rápido mal encaixado; o próprio operador resolveu.', 'demo'),
        ],
        comentarios=[],
    ),
]


class Command(BaseCommand):
    help = 'Cria usuários, ativos e chamados de demonstração. Pode rodar mais de uma vez.'

    @transaction.atomic
    def handle(self, *args, **options):
        usuarios = self._usuarios()
        self._ativos(usuarios['demo'])
        self._chamados(usuarios)

        self.stdout.write(self.style.SUCCESS('Dados de demonstração prontos.'))
        self.stdout.write('Login (pelo e-mail):')
        for _, email, _, _, staff in USUARIOS:
            papel = 'staff' if staff else 'usuário comum'
            self.stdout.write(f'  {email}  senha: {SENHA_DEMO}  ({papel})')

    # ----- usuários -----

    def _usuarios(self):
        usuarios = {}
        for username, email, nome, sobrenome, staff in USUARIOS:
            user = (
                User.objects.filter(email=email).first()
                or User.objects.filter(username=username).first()
            )
            criado = user is None
            if criado:
                user = User(username=username, email=email)

            user.first_name = nome
            user.last_name = sobrenome
            user.is_staff = staff
            user.is_active = True
            if criado or not user.check_password(SENHA_DEMO):
                user.set_password(SENHA_DEMO)
            user.save()

            usuarios[username] = user
            self._log('usuário', email, criado)
        return usuarios

    # ----- ativos -----

    def _ativos(self, responsavel):
        for dados in ATIVOS:
            ativo, criado = Ativo.objects.get_or_create(codigo=dados['codigo'], defaults=dados)
            if criado:
                AtivoHistorico.objects.create(
                    ativo=ativo,
                    tipo='Cadastro',
                    descricao='Ativo cadastrado pela carga de demonstração.',
                    usuario=responsavel,
                )
                if ativo.status == 'Manutenção':
                    AtivoHistorico.objects.create(
                        ativo=ativo,
                        tipo='Manutenção',
                        descricao='Equipamento retirado de operação para avaliação da bateria.',
                        usuario=responsavel,
                    )
            self._log('ativo', f"{ativo.codigo} {ativo.nome}", criado)

    # ----- chamados -----

    def _chamados(self, usuarios):
        agora = timezone.now()
        solicitante = usuarios['demo']

        for dados in CHAMADOS:
            if Chamado.objects.filter(titulo=dados['titulo']).exists():
                self._log('chamado', dados['titulo'], False)
                continue

            criado_em = agora - timedelta(days=dados['dias_atras'])
            sugerida = dados['sugerida_em_dias']

            chamado = Chamado.objects.create(
                titulo=dados['titulo'],
                descricao=dados['descricao'],
                ativo=dados['ativo'],
                ambiente=dados['ambiente'],
                urgencia=dados['urgencia'],
                status=dados['status'],
                solicitante=solicitante,
                data_sugerida=None if sugerida is None else criado_em + timedelta(days=sugerida),
            )
            chamado.responsaveis.set(usuarios[u] for u in dados['responsaveis'])

            for i, (status_, descricao, autor) in enumerate(dados['historico']):
                item = ChamadoStatusHistory.objects.create(
                    chamado=chamado, status=status_, descricao=descricao, usuario=usuarios[autor],
                )
                self._datar(ChamadoStatusHistory, item.pk, criado_em + timedelta(hours=3 * i))

            for j, (autor, texto) in enumerate(dados['comentarios']):
                item = Comentario.objects.create(chamado=chamado, autor=usuarios[autor], texto=texto)
                self._datar(Comentario, item.pk, criado_em + timedelta(hours=4 * j + 1))

            # auto_now_add não aceita valor na criação; datamos depois para o
            # dashboard ter chamados espalhados nos últimos dias.
            Chamado.objects.filter(pk=chamado.pk).update(
                data_criacao=criado_em,
                data_atualizacao=criado_em + timedelta(hours=3 * max(len(dados['historico']) - 1, 0)),
            )
            self._log('chamado', dados['titulo'], True)

    # ----- apoio -----

    @staticmethod
    def _datar(modelo, pk, quando):
        modelo.objects.filter(pk=pk).update(data_criacao=quando)

    def _log(self, tipo, nome, criado):
        marca = 'criado' if criado else 'já existia'
        self.stdout.write(f'  {tipo:<8} {marca:<11} {nome}')
