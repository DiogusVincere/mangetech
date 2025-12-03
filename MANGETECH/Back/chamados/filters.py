"""
Filtros customizados para a API de Chamados
"""

from django_filters import rest_framework as filters
from django.db.models import Q
from .models import Chamado, Ativo


class ChamadoFilter(filters.FilterSet):
    """
    Filtro avançado para Chamados com suporte a:
    - Múltiplos status e urgências
    - Busca por texto
    - Filtros de data
    - Filtro por responsável e solicitante
    - "Meus chamados"
    """
    
    # ========== FILTROS DE STATUS E URGÊNCIA ==========
    
    status = filters.MultipleChoiceFilter(
        choices=Chamado.STATUS_CHOICES,
        field_name='status',
        lookup_expr='iexact',
        help_text='Filtrar por um ou múltiplos status (ex: ABERTO,EM ANDAMENTO)'
    )
    
    urgencia = filters.MultipleChoiceFilter(
        choices=Chamado.URGENCIA_CHOICES,
        field_name='urgencia',
        lookup_expr='iexact',
        help_text='Filtrar por uma ou múltiplas urgências (ex: Crítico,Alta)'
    )
    
    # ========== FILTROS DE LOCALIZAÇÃO ==========
    
    ambiente = filters.CharFilter(
        field_name='ambiente',
        lookup_expr='icontains',
        help_text='Filtrar por ambiente (busca parcial)'
    )
    
    ativo = filters.CharFilter(
        field_name='ativo',
        lookup_expr='icontains',
        help_text='Filtrar por ativo/equipamento (busca parcial)'
    )
    
    # ========== FILTROS DE USUÁRIOS ==========
    
    solicitante = filters.NumberFilter(
        field_name='solicitante__id',
        help_text='Filtrar por ID do solicitante'
    )
    
    solicitante_nome = filters.CharFilter(
        method='filter_solicitante_nome',
        help_text='Filtrar por nome do solicitante'
    )
    
    responsavel = filters.NumberFilter(
        field_name='responsaveis__id',
        help_text='Filtrar por ID do responsável'
    )
    
    responsavel_nome = filters.CharFilter(
        method='filter_responsavel_nome',
        help_text='Filtrar por nome do responsável'
    )
    
    # ========== FILTROS DE DATA ==========
    
    data_inicio = filters.DateFilter(
        field_name='data_criacao',
        lookup_expr='gte',
        help_text='Data inicial (formato: YYYY-MM-DD)'
    )
    
    data_fim = filters.DateFilter(
        field_name='data_criacao',
        lookup_expr='lte',
        help_text='Data final (formato: YYYY-MM-DD)'
    )
    
    data_sugerida_inicio = filters.DateFilter(
        field_name='data_sugerida',
        lookup_expr='gte',
        help_text='Data sugerida inicial (formato: YYYY-MM-DD)'
    )
    
    data_sugerida_fim = filters.DateFilter(
        field_name='data_sugerida',
        lookup_expr='lte',
        help_text='Data sugerida final (formato: YYYY-MM-DD)'
    )
    
    # ========== BUSCA GERAL ==========
    
    search = filters.CharFilter(
        method='filter_search',
        help_text='Busca geral em título, descrição, ativo e ID'
    )
    
    # ========== FILTROS ESPECIAIS ==========
    
    meus_chamados = filters.BooleanFilter(
        method='filter_meus_chamados',
        help_text='Filtrar apenas chamados do usuário logado (true/false)'
    )
    
    criticos_abertos = filters.BooleanFilter(
        method='filter_criticos_abertos',
        help_text='Filtrar apenas chamados críticos/alta urgência em aberto'
    )
    
    sem_responsavel = filters.BooleanFilter(
        method='filter_sem_responsavel',
        help_text='Filtrar chamados sem responsável atribuído'
    )
    
    atrasados = filters.BooleanFilter(
        method='filter_atrasados',
        help_text='Filtrar chamados com data sugerida vencida'
    )
    
    # ========== MÉTODOS CUSTOMIZADOS ==========
    
    def filter_solicitante_nome(self, queryset, name, value):
        """Filtra por nome do solicitante (first_name, last_name ou username)"""
        return queryset.filter(
            Q(solicitante__first_name__icontains=value) |
            Q(solicitante__last_name__icontains=value) |
            Q(solicitante__username__icontains=value)
        )
    
    def filter_responsavel_nome(self, queryset, name, value):
        """Filtra por nome de algum responsável"""
        return queryset.filter(
            Q(responsaveis__first_name__icontains=value) |
            Q(responsaveis__last_name__icontains=value) |
            Q(responsaveis__username__icontains=value)
        ).distinct()
    
    def filter_search(self, queryset, name, value):
        """Busca geral em múltiplos campos"""
        return queryset.filter(
            Q(titulo__icontains=value) |
            Q(descricao__icontains=value) |
            Q(ativo__icontains=value) |
            Q(ambiente__icontains=value) |
            Q(id__icontains=value)
        ).distinct()
    
    def filter_meus_chamados(self, queryset, name, value):
        """Filtra chamados do usuário logado (solicitante ou responsável)"""
        if value and self.request and self.request.user.is_authenticated:
            user = self.request.user
            return queryset.filter(
                Q(solicitante=user) | Q(responsaveis=user)
            ).distinct()
        return queryset
    
    def filter_criticos_abertos(self, queryset, name, value):
        """Filtra chamados críticos ou alta urgência que estão em aberto"""
        if value:
            return queryset.filter(
                urgencia__in=['Crítico', 'Alta'],
                status__in=['ABERTO', 'AGUARDANDO RESP', 'EM ANDAMENTO']
            )
        return queryset
    
    def filter_sem_responsavel(self, queryset, name, value):
        """Filtra chamados sem responsável atribuído"""
        if value:
            return queryset.filter(responsaveis__isnull=True)
        return queryset
    
    def filter_atrasados(self, queryset, name, value):
        """Filtra chamados com data sugerida vencida e ainda não concluídos"""
        if value:
            from django.utils import timezone
            return queryset.filter(
                data_sugerida__lt=timezone.now(),
                status__in=['ABERTO', 'AGUARDANDO RESP', 'EM ANDAMENTO', 'REALIZADO']
            )
        return queryset
    
    class Meta:
        model = Chamado
        fields = [
            'status', 
            'urgencia', 
            'ambiente', 
            'ativo',
            'solicitante', 
            'solicitante_nome',
            'responsavel',
            'responsavel_nome',
            'data_inicio', 
            'data_fim',
            'data_sugerida_inicio',
            'data_sugerida_fim',
            'search',
            'meus_chamados',
            'criticos_abertos',
            'sem_responsavel',
            'atrasados',
        ]


class AtivoFilter(filters.FilterSet):
    """
    Filtro avançado para Ativos/Equipamentos
    """
    
    # ========== FILTROS BÁSICOS ==========
    
    status = filters.MultipleChoiceFilter(
        choices=Ativo.STATUS_CHOICES,
        field_name='status',
        lookup_expr='iexact',
        help_text='Filtrar por status (Ativo, Inativo, Manutenção)'
    )
    
    ambiente = filters.CharFilter(
        field_name='ambiente',
        lookup_expr='icontains',
        help_text='Filtrar por ambiente/localização'
    )
    
    fabricante = filters.CharFilter(
        field_name='fabricante',
        lookup_expr='icontains',
        help_text='Filtrar por fabricante'
    )
    
    # ========== BUSCA ==========
    
    search = filters.CharFilter(
        method='filter_search',
        help_text='Busca em código, nome, modelo, fabricante e número de série'
    )
    
    # ========== FILTROS ESPECIAIS ==========
    
    com_chamados_abertos = filters.BooleanFilter(
        method='filter_com_chamados_abertos',
        help_text='Filtrar ativos com chamados em aberto'
    )
    
    def filter_search(self, queryset, name, value):
        """Busca geral em múltiplos campos"""
        return queryset.filter(
            Q(codigo__icontains=value) |
            Q(nome__icontains=value) |
            Q(modelo__icontains=value) |
            Q(fabricante__icontains=value) |
            Q(numero_serie__icontains=value)
        )
    
    def filter_com_chamados_abertos(self, queryset, name, value):
        """Filtra ativos que têm chamados em aberto"""
        if value:
            from .models import Chamado
            codigos_com_chamados = Chamado.objects.filter(
                status__in=['ABERTO', 'AGUARDANDO RESP', 'EM ANDAMENTO']
            ).values_list('ativo', flat=True).distinct()
            
            # Filtra ativos cujo código aparece nos chamados
            return queryset.filter(
                codigo__in=[codigo for codigo in codigos_com_chamados if codigo]
            )
        return queryset
    
    class Meta:
        model = Ativo
        fields = [
            'status',
            'ambiente',
            'fabricante',
            'search',
            'com_chamados_abertos',
        ]