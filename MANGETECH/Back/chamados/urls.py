# chamados/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    # ViewSets
    ChamadoViewSet,
    ComentarioViewSet,
    AtivoViewSet,
    UserViewSet,
   
    
    # Autenticação
    register_user,
    login_user,
    logout_user,
    recuperar_senha,
    solicitar_recuperacao_senha,
    verificar_token_recuperacao,
    resetar_senha,
    verificar_email_real,
    
    # Outras views
    export_chamados_csv,
    dashboard_gerencial,
    get_user_profile,
    update_user_profile,
    change_password,
    get_user_statistics,
    get_user_statistics_by_id,
)

# ===== ROUTER PARA VIEWSETS =====
router = DefaultRouter()
router.register(r'chamados', ChamadoViewSet, basename='chamado')
router.register(r'comentarios', ComentarioViewSet, basename='comentario')
router.register(r'ativos', AtivoViewSet, basename='ativo')  
router.register(r'usuarios', UserViewSet, basename='usuario')

urlpatterns = [
    # ===== INCLUIR ROTAS DO ROUTER =====
    path('', include(router.urls)),
    
    # ===== USUÁRIOS =====
    path('usuarios/<int:user_id>/estatisticas/', get_user_statistics_by_id, name='user-statistics'),

    
    # ===== AUTENTICAÇÃO =====
    path('auth/register/', register_user, name='register'),
    path('auth/login/', login_user, name='login'),
    path('auth/logout/', logout_user, name='logout'),
    path('auth/recuperar-senha/', recuperar_senha, name='recuperar-senha'),
    path('auth/solicitar-recuperacao-senha/', solicitar_recuperacao_senha, name='solicitar-recuperacao-senha'),
    path('auth/verificar-token-recuperacao/', verificar_token_recuperacao, name='verificar-token-recuperacao'),
    path('auth/resetar-senha/', resetar_senha, name='resetar-senha'),
    path('auth/verificar-email/', verificar_email_real, name='verificar-email'),
    
    # ===== CHAMADOS =====
    path('chamados/export/', export_chamados_csv, name='export-chamados-csv'),
    
    # ===== DASHBOARD =====
    path('dashboard/gerencial/', dashboard_gerencial, name='dashboard-gerencial'),
    
    # ===== PERFIL DO USUÁRIO =====
    path('perfil/', get_user_profile, name='user-profile'),
    path('perfil/atualizar/', update_user_profile, name='update-profile'),
    path('perfil/alterar-senha/', change_password, name='change-password'),
    path('perfil/estatisticas/', get_user_statistics, name='user-statistics'),
    
    # ===== QR CODE =====
    # NOTA: As rotas de QR Code já estão disponíveis via @action no AtivoViewSet:
    # GET /api/chamados/ativos/{id}/qr-code/  -> gerar_qr_code_ativo (via @action, SE EXISTIR)
    # Se você quiser rotas customizadas, descomente abaixo:
    # path('ativos/<int:pk>/qr-code/', gerar_qr_code_ativo, name='gerar-qr-code-ativo'),
    # path('ativos/qr-code/<str:codigo>/', gerar_qr_code_por_codigo, name='gerar-qr-code-por-codigo'),
    # path('ativos/qr-codes/listar/', listar_qr_codes_ativos, name='listar-qr-codes'),
]