from rest_framework.pagination import PageNumberPagination


class Paginacao(PageNumberPagination):
    """50 por página; o cliente pode pedir mais com ?page_size= (até 1000)."""

    page_size = 50
    page_size_query_param = 'page_size'
    max_page_size = 1000
