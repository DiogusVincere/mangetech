from django.contrib import admin
from .models import (
    Chamado,
    ChamadoStatusHistory,
    ChamadoStatusImage,
    ChamadoAnexo,
    Comentario,
    Ativo,
    AtivoHistorico,
    ComentarioFoto
)


class ChamadoStatusImageInline(admin.TabularInline):
    model = ChamadoStatusImage
    extra = 0
    fields = ('imagem', 'data_upload')
    readonly_fields = ('data_upload',)


class ChamadoStatusHistoryInline(admin.TabularInline):
    model = ChamadoStatusHistory
    extra = 0
    fields = ('status', 'descricao', 'usuario', 'data_criacao')
    readonly_fields = ('data_criacao',)


class ChamadoAnexoInline(admin.TabularInline):
    model = ChamadoAnexo
    extra = 0
    fields = ('arquivo', 'nome_original', 'data_upload')
    readonly_fields = ('data_upload',)


class ComentarioInline(admin.TabularInline):
    model = Comentario
    extra = 0
    fields = ('autor', 'texto', 'data_criacao')
    readonly_fields = ('data_criacao',)


@admin.register(Chamado)
class ChamadoAdmin(admin.ModelAdmin):
    list_display = (
        'id', 
        'titulo', 
        'status', 
        'urgencia',
        'solicitante',
        'ambiente',
        'data_criacao'
    )
    list_filter = ('status', 'urgencia', 'ambiente', 'data_criacao')
    search_fields = ('titulo', 'descricao', 'ativo', 'id')
    readonly_fields = ('data_criacao', 'data_atualizacao')
    filter_horizontal = ('responsaveis',)
    
    fieldsets = (
        ('Informações Básicas', {
            'fields': ('titulo', 'descricao', 'ativo', 'ambiente')
        }),
        ('Responsabilidade', {
            'fields': ('solicitante', 'responsaveis')
        }),
        ('Status e Prioridade', {
            'fields': ('status', 'urgencia')
        }),
        ('Datas', {
            'fields': ('data_criacao', 'data_sugerida', 'data_atualizacao')
        }),
    )
    
    inlines = [
        ChamadoStatusHistoryInline,
        ComentarioInline,
        ChamadoAnexoInline
    ]
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'solicitante'
        ).prefetch_related('responsaveis')


@admin.register(ChamadoStatusHistory)
class ChamadoStatusHistoryAdmin(admin.ModelAdmin):
    list_display = ('id', 'chamado', 'status', 'usuario', 'data_criacao')
    list_filter = ('status', 'data_criacao')
    search_fields = ('chamado__titulo', 'descricao')
    readonly_fields = ('data_criacao',)
    
    inlines = [ChamadoStatusImageInline]


@admin.register(ChamadoStatusImage)
class ChamadoStatusImageAdmin(admin.ModelAdmin):
    list_display = ('id', 'historico', 'data_upload')
    list_filter = ('data_upload',)
    readonly_fields = ('data_upload',)


@admin.register(ChamadoAnexo)
class ChamadoAnexoAdmin(admin.ModelAdmin):
    list_display = ('id', 'chamado', 'nome_original', 'data_upload')
    list_filter = ('data_upload',)
    search_fields = ('nome_original', 'chamado__titulo')
    readonly_fields = ('data_upload',)

class ComentarioFotoInline(admin.TabularInline):
    model = ComentarioFoto
    extra = 0
    fields = ('imagem', 'data_upload')
    readonly_fields = ('data_upload',)


@admin.register(Comentario)
class ComentarioAdmin(admin.ModelAdmin):
    list_display = ('id', 'chamado', 'autor', 'data_criacao')
    list_filter = ('data_criacao',)
    search_fields = ('texto', 'chamado__titulo', 'autor__username')
    readonly_fields = ('data_criacao',)
    inlines = [ComentarioFotoInline]


class AtivoHistoricoInline(admin.TabularInline):
    model = AtivoHistorico
    extra = 0
    fields = ('tipo', 'descricao', 'usuario', 'data_criacao')
    readonly_fields = ('data_criacao',)


@admin.register(Ativo)
class AtivoAdmin(admin.ModelAdmin):
    list_display = (
        'codigo',
        'nome',
        'modelo',
        'ambiente',
        'status',
        'data_cadastro'
    )
    list_filter = ('status', 'ambiente', 'fabricante')
    search_fields = ('codigo', 'nome', 'modelo', 'numero_serie')
    readonly_fields = ('data_cadastro', 'data_atualizacao')
    
    fieldsets = (
        ('Identificação', {
            'fields': ('codigo', 'nome', 'modelo')
        }),
        ('Detalhes Técnicos', {
            'fields': ('fabricante', 'numero_serie', 'fornecedor')
        }),
        ('Localização e Status', {
            'fields': ('ambiente', 'status')
        }),
        ('Datas', {
            'fields': ('data_cadastro', 'data_atualizacao')
        }),
    )
    
    inlines = [AtivoHistoricoInline]


@admin.register(AtivoHistorico)
class AtivoHistoricoAdmin(admin.ModelAdmin):
    list_display = ('id', 'ativo', 'tipo', 'usuario', 'data_criacao')
    list_filter = ('tipo', 'data_criacao')
    search_fields = ('ativo__codigo', 'ativo__nome', 'descricao')
    readonly_fields = ('data_criacao',)