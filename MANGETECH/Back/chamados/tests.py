"""Testes da API do MangeTech.

    python manage.py test chamados
"""

import shutil
import tempfile
from datetime import date, timedelta
from io import BytesIO
from unittest import mock

from django.contrib.auth.models import User
from django.core import mail
from django.core.cache import cache
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.utils import timezone
from PIL import Image
from rest_framework.authtoken.models import Token
from rest_framework.test import APITestCase

from .models import Ativo, AtivoHistorico, Chamado, ChamadoStatusHistory, TokenRecuperacaoSenha

MEDIA_TMP = tempfile.mkdtemp(prefix='mangetech-test-media-')


def png(nome='foto.png'):
    buf = BytesIO()
    Image.new('RGB', (4, 4), 'red').save(buf, format='PNG')
    return SimpleUploadedFile(nome, buf.getvalue(), content_type='image/png')


@override_settings(
    MEDIA_ROOT=MEDIA_TMP,
    EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend',
    PASSWORD_HASHERS=['django.contrib.auth.hashers.MD5PasswordHasher'],
)
class Base(APITestCase):
    @classmethod
    def tearDownClass(cls):
        super().tearDownClass()
        shutil.rmtree(MEDIA_TMP, ignore_errors=True)

    def setUp(self):
        cache.clear()  # zera o limite de tentativas de login entre testes
        self.admin = User.objects.create_user('admin@x.com', 'admin@x.com', 'senha123', first_name='Ana', is_staff=True)
        self.tec = User.objects.create_user('tec@x.com', 'tec@x.com', 'senha123', first_name='Téo')
        self.outro = User.objects.create_user('outro@x.com', 'outro@x.com', 'senha123', first_name='Olga')
        self.ativo = Ativo.objects.create(codigo='AST-001', nome='Compressor', modelo='GA', ambiente='Sala 1')
        self.ativo10 = Ativo.objects.create(codigo='AST-0010', nome='Bomba', modelo='B', ambiente='Sala 2')

    def entrar(self, user):
        self.client.force_authenticate(user)

    def criar_chamado(self, user=None, **extra):
        self.entrar(user or self.admin)
        dados = {
            'titulo': 'Compressor parado',
            'descricao': 'Desarma depois de 20 minutos ligado.',
            'ativo': 'AST-001',
            'ambiente': 'Sala 1',
            'urgencia': 'Alta',
        }
        dados.update(extra)
        r = self.client.post('/api/chamados/', dados, format='json')
        self.assertEqual(r.status_code, 201, r.content)
        return r.json()


class AuthTests(Base):
    def test_login_por_email_e_senha_errada(self):
        r = self.client.post('/api/auth/login/', {'email': 'ADMIN@x.com', 'senha': 'senha123'}, format='json')
        self.assertEqual(r.status_code, 200)
        self.assertTrue(r.json()['token'])
        r = self.client.post('/api/auth/login/', {'email': 'admin@x.com', 'senha': 'errada'}, format='json')
        self.assertEqual(r.status_code, 401)
        self.assertIn('incorretos', r.json()['message'])

    def test_login_usuario_inativo(self):
        self.tec.is_active = False
        self.tec.save()
        r = self.client.post('/api/auth/login/', {'email': 'tec@x.com', 'senha': 'senha123'}, format='json')
        self.assertEqual(r.status_code, 401)
        self.assertIn('inativa', r.json()['message'])

    def test_cadastro_e_email_duplicado(self):
        r = self.client.post('/api/auth/register/', {'nome': 'Novo Usuário', 'email': 'novo@x.com', 'senha': '123456'}, format='json')
        self.assertEqual(r.status_code, 400)  # senha só numérica/comum
        r = self.client.post('/api/auth/register/', {'nome': 'Novo Usuário', 'email': 'novo@x.com', 'senha': 'Torno#2026'}, format='json')
        self.assertEqual(r.status_code, 201, r.content)
        self.assertEqual(r.json()['user']['first_name'], 'Novo')
        r = self.client.post('/api/auth/register/', {'nome': 'Outro', 'email': 'NOVO@x.com', 'senha': 'Torno#2026'}, format='json')
        self.assertEqual(r.status_code, 400)
        self.assertIn('cadastrado', r.json()['message'])

    def test_recuperacao_de_senha_completa(self):
        r = self.client.post('/api/auth/solicitar-recuperacao-senha/', {'email': 'tec@x.com'}, format='json')
        self.assertEqual(r.status_code, 200, r.content)
        self.assertEqual(len(mail.outbox), 1)
        codigo = TokenRecuperacaoSenha.objects.get(user=self.tec).token
        self.assertIn(codigo, mail.outbox[0].body)

        # Conferir o código não pode consumi-lo (era o bug que travava o reset).
        r = self.client.post('/api/auth/verificar-token-recuperacao/', {'email': 'tec@x.com', 'token': codigo}, format='json')
        self.assertEqual(r.status_code, 200, r.content)

        r = self.client.post('/api/auth/resetar-senha/', {
            'email': 'tec@x.com', 'token': codigo, 'nova_senha': 'nova1234', 'confirmar_senha': 'nova1234',
        }, format='json')
        self.assertEqual(r.status_code, 200, r.content)
        self.tec.refresh_from_db()
        self.assertTrue(self.tec.check_password('nova1234'))
        self.assertNotIn('nova1234', mail.outbox[-1].body)  # senha nunca vai por e-mail

        # Código é de uso único.
        r = self.client.post('/api/auth/resetar-senha/', {
            'email': 'tec@x.com', 'token': codigo, 'nova_senha': 'outra123', 'confirmar_senha': 'outra123',
        }, format='json')
        self.assertEqual(r.status_code, 400)

    def test_recuperacao_nao_revela_email_inexistente(self):
        r1 = self.client.post('/api/auth/solicitar-recuperacao-senha/', {'email': 'tec@x.com'}, format='json')
        r2 = self.client.post('/api/auth/solicitar-recuperacao-senha/', {'email': 'ninguem@x.com'}, format='json')
        self.assertEqual(r1.status_code, r2.status_code)
        self.assertEqual(r1.json()['message'], r2.json()['message'])

    def test_codigo_errado_conta_tentativas(self):
        self.client.post('/api/auth/solicitar-recuperacao-senha/', {'email': 'tec@x.com'}, format='json')
        certo = TokenRecuperacaoSenha.objects.get(user=self.tec).token
        errado = '000000' if certo != '000000' else '111111'
        for _ in range(5):
            r = self.client.post('/api/auth/verificar-token-recuperacao/', {'email': 'tec@x.com', 'token': errado}, format='json')
            self.assertEqual(r.status_code, 400)
        r = self.client.post('/api/auth/verificar-token-recuperacao/', {'email': 'tec@x.com', 'token': certo}, format='json')
        self.assertEqual(r.status_code, 400)
        self.assertTrue(r.json().get('token_expirado'))

    def test_codigo_numerico_no_json_nao_quebra(self):
        self.client.post('/api/auth/solicitar-recuperacao-senha/', {'email': 'tec@x.com'}, format='json')
        r = self.client.post('/api/auth/verificar-token-recuperacao/', {'email': 'tec@x.com', 'token': 1}, format='json')
        self.assertEqual(r.status_code, 400)

    def test_verificar_email_sem_travar(self):
        with mock.patch('chamados.email_service.VerificadorEmail.validar_dominio', return_value=False):
            r = self.client.post('/api/auth/verificar-email/', {'email': 'a@dominio-que-nao-existe.zz'}, format='json')
        self.assertEqual(r.status_code, 400)
        with mock.patch('chamados.email_service.VerificadorEmail.validar_dominio', return_value=True):
            r = self.client.post('/api/auth/verificar-email/', {'email': 'a@exemplo.com'}, format='json')
        self.assertEqual(r.status_code, 200)
        self.assertTrue(r.json()['valido'])

    def test_trocar_senha_devolve_token_novo(self):
        token = Token.objects.create(user=self.tec)
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')
        r = self.client.post('/api/perfil/alterar-senha/', {
            'senha_atual': 'senha123', 'nova_senha': 'nova1234', 'confirmar_senha': 'nova1234',
        }, format='json')
        self.assertEqual(r.status_code, 200)
        self.assertNotEqual(r.json()['token'], token.key)


class ChamadoTests(Base):
    def test_criar_vincula_ativo_sem_confundir_codigo_parecido(self):
        dados = self.criar_chamado(ativo='AST-001 - Compressor')
        self.assertEqual(dados['ativo_ref'], self.ativo.id)
        self.assertEqual(dados['ativo_detalhes']['codigo'], 'AST-001')
        # Um só registro de "criado" no histórico (antes saíam dois).
        self.assertEqual(ChamadoStatusHistory.objects.filter(chamado_id=dados['id']).count(), 1)
        self.assertTrue(AtivoHistorico.objects.filter(ativo=self.ativo, tipo='Chamado aberto').exists())

        r = self.client.get(f'/api/ativos/{self.ativo10.id}/chamados/')
        self.assertEqual(r.json()['chamados'], [])
        r = self.client.get(f'/api/ativos/{self.ativo.id}/chamados/')
        self.assertEqual(len(r.json()['chamados']), 1)

    def test_texto_do_ativo_cabe_no_campo(self):
        longo = Ativo.objects.create(codigo='LINHA-2-PRENSA-01', nome='P' * 200, modelo='X')
        dados = self.criar_chamado(ativo='', ativo_ref=longo.id)
        self.assertEqual(len(dados['ativo']), 200)

    def test_criar_pelo_id_do_ativo_preenche_texto_e_ambiente(self):
        dados = self.criar_chamado(ativo='', ativo_ref=self.ativo10.id, ambiente='')
        self.assertEqual(dados['ativo'], 'AST-0010 - Bomba')
        self.assertEqual(dados['ambiente'], 'Sala 2')

    def test_usuario_comum_so_ve_os_seus(self):
        self.criar_chamado(self.admin)
        meu = self.criar_chamado(self.tec, titulo='Meu chamado')
        self.entrar(self.tec)
        r = self.client.get('/api/chamados/')
        self.assertEqual([c['id'] for c in r.json()['results']], [meu['id']])
        self.entrar(self.outro)
        self.assertEqual(self.client.get(f"/api/chamados/{meu['id']}/").status_code, 404)

    def test_mudar_status_com_foto_e_validacao(self):
        c = self.criar_chamado()
        r = self.client.post(f"/api/chamados/{c['id']}/mudar_status/", {
            'status': 'EM ANDAMENTO', 'descricao': 'Técnico a caminho do local.', 'fotos': [png()],
        }, format='multipart')
        self.assertEqual(r.status_code, 200, r.content)
        self.assertEqual(r.json()['chamado']['status'], 'EM ANDAMENTO')
        self.assertEqual(len(r.json()['chamado']['historico'][0]['fotos']), 1)

        r = self.client.post(f"/api/chamados/{c['id']}/mudar_status/", {'status': 'CONCLUÍDO', 'descricao': 'curta'})
        self.assertEqual(r.status_code, 400)
        self.assertIn('10', r.json()['message'])

    def test_comentario_valido_e_vazio(self):
        c = self.criar_chamado()
        r = self.client.post(f"/api/chamados/{c['id']}/adicionar_comentario/", {'texto': 'Peça pedida', 'fotos': [png()]},
                             format='multipart')
        self.assertEqual(r.status_code, 201, r.content)
        self.assertEqual(len(r.json()['comentario']['fotos']), 1)
        # Antes: erro 500 (variável indefinida) com texto vazio.
        r = self.client.post(f"/api/chamados/{c['id']}/adicionar_comentario/", {'texto': ''}, format='multipart')
        self.assertEqual(r.status_code, 400)

    def test_anexo_enviar_e_remover(self):
        c = self.criar_chamado()
        arquivo = SimpleUploadedFile('nota.pdf', b'%PDF-1.4 teste', content_type='application/pdf')
        r = self.client.post(f"/api/chamados/{c['id']}/adicionar_anexo/", {'arquivo': arquivo}, format='multipart')
        self.assertEqual(r.status_code, 201, r.content)
        anexo_id = r.json()['anexo']['id']
        r = self.client.delete(f"/api/chamados/{c['id']}/anexos/{anexo_id}/")
        self.assertEqual(r.status_code, 204)

    def test_excluir_em_andamento_da_400_e_nao_500(self):
        c = self.criar_chamado()
        self.client.post(f"/api/chamados/{c['id']}/mudar_status/", {'status': 'EM ANDAMENTO', 'descricao': 'Começando o serviço.'})
        r = self.client.delete(f"/api/chamados/{c['id']}/")
        self.assertEqual(r.status_code, 400)
        r = self.client.post('/api/chamados/bulk-delete/', {'ids': [int(c['id'])]}, format='json')
        self.assertEqual(r.json()['quantidade_excluida'], 0)
        self.assertTrue(Chamado.objects.filter(pk=c['id']).exists())

    def test_responsavel_nao_exclui_chamado_alheio(self):
        c = self.criar_chamado(self.admin, responsaveis=[self.tec.id])
        self.entrar(self.tec)
        self.assertEqual(self.client.delete(f"/api/chamados/{c['id']}/").status_code, 403)

    def test_editar_status_registra_historico(self):
        c = self.criar_chamado()
        r = self.client.patch(f"/api/chamados/{c['id']}/", {'status': 'CANCELADO', 'titulo': 'Título novo'}, format='json')
        self.assertEqual(r.status_code, 200, r.content)
        self.assertEqual(r.json()['titulo'], 'Título novo')
        self.assertEqual(ChamadoStatusHistory.objects.filter(chamado_id=c['id']).count(), 2)

    def test_export_csv_acessivel_e_filtrado(self):
        self.criar_chamado(titulo='Alta urgência')
        self.criar_chamado(titulo='Baixa urgência', urgencia='Baixa')
        r = self.client.get('/api/chamados/export/', {'urgencia': 'Baixa'})
        self.assertEqual(r.status_code, 200)
        texto = r.content.decode('utf-8-sig')
        self.assertIn('Baixa urgência', texto)
        self.assertNotIn('Alta urgência', texto)

    def test_filtros_status_com_virgula_e_repetido(self):
        a = self.criar_chamado(titulo='Um')
        self.criar_chamado(titulo='Dois')
        self.client.post(f"/api/chamados/{a['id']}/mudar_status/", {'status': 'EM ANDAMENTO', 'descricao': 'Começando o serviço.'})
        r1 = self.client.get('/api/chamados/?status=EM ANDAMENTO,CANCELADO')
        r2 = self.client.get('/api/chamados/?status=EM ANDAMENTO&status=CANCELADO')
        self.assertEqual(r1.json()['count'], 1)
        self.assertEqual(r2.json()['count'], 1)
        self.assertEqual(self.client.get('/api/chamados/?status=ABERTO,EM ANDAMENTO').json()['count'], 2)

    def test_busca_por_numero_e_page_size(self):
        c = self.criar_chamado()
        r = self.client.get(f"/api/chamados/?search=%23{c['id']}")
        self.assertEqual(r.json()['count'], 1)
        r = self.client.get('/api/chamados/?page_size=1')
        self.assertEqual(len(r.json()['results']), 1)
        self.assertNotIn('historico', r.json()['results'][0])  # lista enxuta
        self.assertIn('historico', self.client.get(f"/api/chamados/{c['id']}/").json())

    def test_desvincular_ativo_e_respeitado(self):
        c = self.criar_chamado(ativo='AST-001 - Compressor')
        r = self.client.patch(f"/api/chamados/{c['id']}/", {'ativo_ref': None}, format='json')
        self.assertEqual(r.status_code, 200, r.content)
        self.assertIsNone(r.json()['ativo_ref'])
        self.assertIsNone(Chamado.objects.get(pk=c['id']).ativo_ref_id)

    def test_anexo_html_baixa_em_vez_de_abrir(self):
        c = self.criar_chamado()
        arquivo = SimpleUploadedFile('x.html', b'<script>alert(1)</script>', content_type='text/html')
        r = self.client.post(f"/api/chamados/{c['id']}/adicionar_anexo/", {'arquivo': arquivo}, format='multipart')
        caminho = r.json()['anexo']['url'].split('://', 1)[1].split('/', 1)[1]
        r = self.client.get('/' + caminho)
        self.assertEqual(r['Content-Disposition'], 'attachment')
        self.assertEqual(r['X-Content-Type-Options'], 'nosniff')
        self.assertEqual(r['Content-Security-Policy'], 'sandbox')

    def test_atrasado(self):
        self.criar_chamado(data_sugerida=(timezone.now() - timedelta(days=1)).isoformat())
        r = self.client.get('/api/chamados/?atrasados=true')
        self.assertEqual(r.json()['count'], 1)
        self.assertTrue(r.json()['results'][0]['atrasado'])


class AtivoTests(Base):
    def test_cadastro_so_admin_e_codigo_unico(self):
        self.entrar(self.tec)
        r = self.client.post('/api/ativos/', {'codigo': 'X-1', 'nome': 'Furadeira', 'modelo': 'F'}, format='json')
        self.assertEqual(r.status_code, 403)
        self.entrar(self.admin)
        r = self.client.post('/api/ativos/', {
            'codigo': 'X-1', 'nome': 'Furadeira', 'modelo': 'F', 'data_aquisicao': '2024-01-31',
            'valor': '1500.50', 'garantia_meses': 13, 'observacoes': 'Com maleta',
        }, format='json')
        self.assertEqual(r.status_code, 201, r.content)
        corpo = r.json()
        self.assertEqual(corpo['garantia_ate'], '2025-02-28')
        self.assertEqual(corpo['valor'], '1500.50')
        self.assertEqual(corpo['historico_movimentacoes'][0]['tipo'], 'Cadastro')
        for codigo in ('X-1', 'x-1'):
            r = self.client.post('/api/ativos/', {'codigo': codigo, 'nome': 'Outra', 'modelo': 'F'}, format='json')
            self.assertEqual(r.status_code, 400)
            self.assertEqual(r.json()['message'], 'Já existe um ativo com este código.')

    def test_editar_status_e_ambiente_gera_historico(self):
        self.entrar(self.tec)
        r = self.client.patch(f'/api/ativos/{self.ativo.id}/', {'status': 'Manutenção', 'ambiente': 'Oficina'}, format='json')
        self.assertEqual(r.status_code, 200, r.content)
        tipos = set(AtivoHistorico.objects.filter(ativo=self.ativo).values_list('tipo', flat=True))
        self.assertEqual(tipos, {'Mudança de status', 'Movimentação'})

    def test_nao_exclui_ativo_com_chamado_aberto(self):
        self.criar_chamado()
        r = self.client.delete(f'/api/ativos/{self.ativo.id}/')
        self.assertEqual(r.status_code, 400)
        r = self.client.delete(f'/api/ativos/{self.ativo10.id}/')
        self.assertEqual(r.status_code, 204)

    def test_qr_code_e_busca_por_codigo(self):
        self.entrar(self.tec)
        r = self.client.get(f'/api/ativos/{self.ativo.id}/qr-code/')
        self.assertTrue(r.json()['qr_code'].startswith('data:image/png;base64,'))
        r = self.client.get(f'/api/ativos/{self.ativo.id}/qr-code/png/')
        self.assertEqual(r['Content-Type'], 'image/png')
        r = self.client.get('/api/ativos/ast-001/por_qrcode/')
        self.assertEqual(r.json()['ativo']['id'], self.ativo.id)
        r = self.client.get('/api/ativos/por-codigo/', {'codigo': 'AST-0010'})
        self.assertEqual(r.json()['ativo']['id'], self.ativo10.id)

    def test_contagem_de_chamados(self):
        self.criar_chamado()
        r = self.client.get('/api/ativos/')
        por_codigo = {a['codigo']: a for a in r.json()['results']}
        self.assertEqual(por_codigo['AST-001']['total_chamados'], 1)
        self.assertEqual(por_codigo['AST-001']['ultimo_chamado']['titulo'], 'Compressor parado')
        self.assertIsNone(por_codigo['AST-0010']['ultimo_chamado'])
        self.assertEqual(por_codigo['AST-0010']['total_chamados'], 0)


class UsuarioEDashboardTests(Base):
    def test_staff_nao_vira_superusuario_sozinho(self):
        self.entrar(self.admin)
        r = self.client.patch(f'/api/usuarios/{self.tec.id}/', {'is_superuser': True}, format='json')
        self.assertEqual(r.status_code, 403)
        r = self.client.patch(f'/api/usuarios/{self.tec.id}/', {'is_staff': True}, format='json')
        self.assertEqual(r.status_code, 200)
        r = self.client.patch(f'/api/usuarios/{self.admin.id}/', {'is_staff': False}, format='json')
        self.assertEqual(r.status_code, 403)

    def test_usuario_comum_nao_edita_usuarios(self):
        self.entrar(self.tec)
        r = self.client.patch(f'/api/usuarios/{self.tec.id}/', {'is_staff': True}, format='json')
        self.assertEqual(r.status_code, 403)

    def test_dashboard_tempo_medio_real(self):
        c = self.criar_chamado()
        ChamadoStatusHistory.objects.create(chamado_id=c['id'], status='REALIZADO', descricao='Feito', usuario=self.admin)
        Chamado.objects.filter(pk=c['id']).update(data_criacao=timezone.now() - timedelta(hours=3))
        r = self.client.get('/api/dashboard/gerencial/')
        dados = r.json()['data']
        self.assertEqual(dados['tempo_resolucao']['2_4h'], 1)
        self.assertAlmostEqual(dados['kpis']['tempo_medio_horas'], 3.0, delta=0.2)
        self.assertEqual(dados['ativos']['mais_chamados'][0]['codigo'], 'AST-001')
        # Janelas fixas não encolhem com ?dias.
        Chamado.objects.filter(pk=c['id']).update(data_criacao=timezone.now() - timedelta(days=60))
        dados = self.client.get('/api/dashboard/gerencial/?dias=30').json()['data']
        self.assertEqual(dados['kpis']['total_chamados'], 0)
        self.assertEqual(dados['periodo']['ultimos_90_dias'], 1)

    def test_estatisticas_com_atividades(self):
        c = self.criar_chamado(self.tec)
        self.entrar(self.admin)
        r = self.client.get(f'/api/usuarios/{self.tec.id}/estatisticas/')
        dados = r.json()['data']
        self.assertEqual(dados['chamados_solicitados'], 1)
        self.assertEqual(dados['atividades_recentes'][0]['chamado_id'], int(c['id']))


class ModeloTests(Base):
    def test_garantia_ate_fim_de_mes(self):
        self.ativo.data_aquisicao = date(2023, 1, 31)
        self.ativo.garantia_meses = 1
        self.assertEqual(self.ativo.garantia_ate, date(2023, 2, 28))
