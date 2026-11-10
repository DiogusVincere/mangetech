"""Filtros da API de chamados e ativos."""

from django.db.models import Q
from django.utils import timezone
from django_filters import rest_framework as filters

from .models import Ativo, Chamado

STATUS_EM_ABERTO = ['ABERTO', 'AGUARDANDO RESP', 'EM ANDAMENTO']


def _valores(data, nome):
    """Lê um parâmetro que pode vir repetido (?status=A&status=B) ou separado
    por vírgula (?status=A,B) — o app Flutter manda do segundo jeito."""
    if hasattr(data, 'getlist'):
        brutos = data.getlist(nome)
    else:
        bruto = data.get(nome)
        brutos = bruto if isinstance(bruto, (list, tuple)) else [bruto]
    valores = []
    for bruto in brutos:
        valores += [v.strip() for v in str(bruto or '').split(',') if v.strip()]
    return valores


class ChamadoFilter(filters.FilterSet):
    status = filters.CharFilter(method='filter_status', help_text='Um ou mais status (ABERTO,EM ANDAMENTO)')
    urgencia = filters.CharFilter(method='filter_urgencia', help_text='Uma ou mais urgências (Crítico,Alta)')

    ambiente = filters.CharFilter(field_name='ambiente', lookup_expr='icontains')
    ativo = filters.CharFilter(field_name='ativo', lookup_expr='icontains')
    ativo_ref = filters.NumberFilter(field_name='ativo_ref__id')

    solicitante = filters.NumberFilter(field_name='solicitante__id')
    solicitante_nome = filters.CharFilter(method='filter_solicitante_nome')
    responsavel = filters.NumberFilter(method='filter_responsavel')
    responsavel_nome = filters.CharFilter(method='filter_responsavel_nome')

    # Datas comparadas pelo dia (data_fim inclui o dia inteiro).
    data_inicio = filters.DateFilter(field_name='data_criacao', lookup_expr='date__gte')
    data_fim = filters.DateFilter(field_name='data_criacao', lookup_expr='date__lte')
    data_sugerida_inicio = filters.DateFilter(field_name='data_sugerida', lookup_expr='date__gte')
    data_sugerida_fim = filters.DateFilter(field_name='data_sugerida', lookup_expr='date__lte')

    search = filters.CharFilter(method='filter_search', help_text='Busca em título, descrição, ativo, ambiente e nº')

    meus_chamados = filters.BooleanFilter(method='filter_meus_chamados')
    criticos_abertos = filters.BooleanFilter(method='filter_criticos_abertos')
    sem_responsavel = filters.BooleanFilter(method='filter_sem_responsavel')
    atrasados = filters.BooleanFilter(method='filter_atrasados')

    class Meta:
        model = Chamado
        fields = []

    def filter_status(self, queryset, name, value):
        valores = _valores(self.data, name)
        return queryset.filter(status__in=valores) if valores else queryset

    def filter_urgencia(self, queryset, name, value):
        valores = _valores(self.data, name)
        return queryset.filter(urgencia__in=valores) if valores else queryset

    def filter_solicitante_nome(self, queryset, name, value):
        return queryset.filter(
            Q(solicitante__first_name__icontains=value)
            | Q(solicitante__last_name__icontains=value)
            | Q(solicitante__username__icontains=value)
        )

    def filter_responsavel(self, queryset, name, value):
        ids = Chamado.objects.filter(responsaveis__id=value).values('pk')
        return queryset.filter(pk__in=ids)

    def filter_responsavel_nome(self, queryset, name, value):
        ids = Chamado.objects.filter(
            Q(responsaveis__first_name__icontains=value)
            | Q(responsaveis__last_name__icontains=value)
            | Q(responsaveis__username__icontains=value)
        ).values('pk')
        return queryset.filter(pk__in=ids)

    def filter_search(self, queryset, name, value):
        value = value.strip().lstrip('#')
        if not value:
            return queryset
        cond = (
            Q(titulo__icontains=value)
            | Q(descricao__icontains=value)
            | Q(ativo__icontains=value)
            | Q(ambiente__icontains=value)
        )
        if value.isdigit():
            cond |= Q(id=int(value))
        return queryset.filter(cond)

    def filter_meus_chamados(self, queryset, name, value):
        user = getattr(self.request, 'user', None)
        if value and user and user.is_authenticated:
            ids = Chamado.objects.filter(Q(solicitante=user) | Q(responsaveis=user)).values('pk')
            return queryset.filter(pk__in=ids)
        return queryset

    def filter_criticos_abertos(self, queryset, name, value):
        if value:
            return queryset.filter(urgencia__in=['Crítico', 'Alta'], status__in=STATUS_EM_ABERTO)
        return queryset

    def filter_sem_responsavel(self, queryset, name, value):
        if value:
            return queryset.filter(responsaveis__isnull=True)
        return queryset

    def filter_atrasados(self, queryset, name, value):
        if value:
            return queryset.filter(
                data_sugerida__lt=timezone.now(),
                status__in=STATUS_EM_ABERTO + ['REALIZADO'],
            )
        return queryset


class AtivoFilter(filters.FilterSet):
    status = filters.CharFilter(method='filter_status', help_text='Ativo, Inativo, Manutenção (aceita vírgula)')
    ambiente = filters.CharFilter(field_name='ambiente', lookup_expr='icontains')
    fabricante = filters.CharFilter(field_name='fabricante', lookup_expr='icontains')
    codigo = filters.CharFilter(field_name='codigo', lookup_expr='iexact')
    search = filters.CharFilter(method='filter_search')
    com_chamados_abertos = filters.BooleanFilter(method='filter_com_chamados_abertos')

    class Meta:
        model = Ativo
        fields = []

    def filter_status(self, queryset, name, value):
        valores = _valores(self.data, name)
        return queryset.filter(status__in=valores) if valores else queryset

    def filter_search(self, queryset, name, value):
        value = value.strip()
        if not value:
            return queryset
        return queryset.filter(
            Q(codigo__icontains=value)
            | Q(nome__icontains=value)
            | Q(modelo__icontains=value)
            | Q(fabricante__icontains=value)
            | Q(numero_serie__icontains=value)
            | Q(ambiente__icontains=value)
        )

    def filter_com_chamados_abertos(self, queryset, name, value):
        if value:
            ids = Chamado.objects.filter(status__in=STATUS_EM_ABERTO, ativo_ref__isnull=False).values('ativo_ref')
            return queryset.filter(pk__in=ids)
        return queryset
