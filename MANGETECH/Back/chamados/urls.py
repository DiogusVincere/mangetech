from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AtivoViewSet,
    ChamadoViewSet,
    ComentarioViewSet,
    UserViewSet,
    change_password,
    dashboard_gerencial,
    get_user_profile,
    get_user_statistics,
    get_user_statistics_by_id,
    login_user,
    logout_user,
    recuperar_senha,
    register_user,
    resetar_senha,
    solicitar_recuperacao_senha,
    update_user_profile,
    verificar_email_real,
    verificar_token_recuperacao,
)

router = DefaultRouter()
router.register(r'chamados', ChamadoViewSet, basename='chamado')
router.register(r'comentarios', ComentarioViewSet, basename='comentario')
router.register(r'ativos', AtivoViewSet, basename='ativo')
router.register(r'usuarios', UserViewSet, basename='usuario')

# GET /api/chamados/export/ é uma action do ChamadoViewSet (vem antes da rota de detalhe).
urlpatterns = [
    path('usuarios/<int:user_id>/estatisticas/', get_user_statistics_by_id, name='user-statistics-by-id'),

    path('auth/register/', register_user, name='register'),
    path('auth/login/', login_user, name='login'),
    path('auth/logout/', logout_user, name='logout'),
    path('auth/recuperar-senha/', recuperar_senha, name='recuperar-senha'),
    path('auth/solicitar-recuperacao-senha/', solicitar_recuperacao_senha, name='solicitar-recuperacao-senha'),
    path('auth/verificar-token-recuperacao/', verificar_token_recuperacao, name='verificar-token-recuperacao'),
    path('auth/resetar-senha/', resetar_senha, name='resetar-senha'),
    path('auth/verificar-email/', verificar_email_real, name='verificar-email'),

    path('dashboard/gerencial/', dashboard_gerencial, name='dashboard-gerencial'),

    path('perfil/', get_user_profile, name='user-profile'),
    path('perfil/atualizar/', update_user_profile, name='update-profile'),
    path('perfil/alterar-senha/', change_password, name='change-password'),
    path('perfil/estatisticas/', get_user_statistics, name='user-statistics'),

    path('', include(router.urls)),
]
