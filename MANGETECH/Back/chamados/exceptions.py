"""Respostas de erro com um campo `message` legível, para web e app mostrarem."""

from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import exception_handler


def primeira_mensagem(dados):
    if isinstance(dados, dict):
        if 'message' in dados:
            return str(dados['message'])
        if 'detail' in dados:
            return str(dados['detail'])
        for valor in dados.values():
            texto = primeira_mensagem(valor)
            if texto:
                return texto
        return ''
    if isinstance(dados, (list, tuple)):
        for valor in dados:
            texto = primeira_mensagem(valor)
            if texto:
                return texto
        return ''
    return str(dados) if dados is not None else ''


def tratar_excecao(exc, context):
    if isinstance(exc, DjangoValidationError):
        mensagens = exc.messages or ['Dados inválidos.']
        return Response({'success': False, 'message': mensagens[0], 'errors': mensagens},
                        status=status.HTTP_400_BAD_REQUEST)

    response = exception_handler(exc, context)
    if response is None:
        return None

    dados = response.data
    if isinstance(dados, dict):
        dados.setdefault('success', False)
        dados.setdefault('message', primeira_mensagem(dados))
    elif isinstance(dados, list):
        response.data = {'success': False, 'message': primeira_mensagem(dados), 'errors': dados}
    return response
