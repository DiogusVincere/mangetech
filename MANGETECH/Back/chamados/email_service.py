"""Verificação de e-mail e envio dos e-mails de recuperação de senha."""

import logging
import re

from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
from django.utils.html import strip_tags

logger = logging.getLogger(__name__)

_EMAIL_RE = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')


class VerificadorEmail:
    """Confere a sintaxe e se o domínio recebe e-mail (registro MX ou A).

    Não tenta VRFY por SMTP: a maioria dos servidores bloqueia a porta 25 e a
    checagem travava a requisição por vários segundos sem resposta útil.
    """

    TIMEOUT_DNS = 3.0

    @staticmethod
    def validar_sintaxe(email: str) -> bool:
        return bool(_EMAIL_RE.match(email or ''))

    @staticmethod
    def validar_dominio(email: str) -> bool | None:
        """True/False quando o DNS responde; None quando não deu para checar."""
        try:
            import dns.exception
            import dns.resolver
        except ImportError:
            return None

        dominio = email.rsplit('@', 1)[-1]
        resolver = dns.resolver.Resolver()
        resolver.lifetime = VerificadorEmail.TIMEOUT_DNS
        resolver.timeout = VerificadorEmail.TIMEOUT_DNS
        for tipo in ('MX', 'A'):
            try:
                resolver.resolve(dominio, tipo)
                return True
            except (dns.resolver.NXDOMAIN, dns.resolver.NoNameservers):
                return False
            except dns.resolver.NoAnswer:
                continue
            except dns.exception.DNSException as exc:  # timeout, rede fora
                logger.warning('Não foi possível checar o domínio %s: %s', dominio, exc)
                return None
        return False

    @staticmethod
    def verificar_email_completo(email: str) -> dict:
        resultado = {
            'email': email,
            'valido': False,
            'sintaxe_ok': False,
            'dominio_ok': False,
            'mensagem': '',
        }
        if not VerificadorEmail.validar_sintaxe(email):
            resultado['mensagem'] = 'Formato de e-mail inválido.'
            return resultado
        resultado['sintaxe_ok'] = True

        dominio = VerificadorEmail.validar_dominio(email)
        if dominio is False:
            resultado['mensagem'] = 'O domínio do e-mail não existe ou não recebe e-mails.'
            return resultado

        # dominio None = DNS indisponível: não bloqueia o usuário por isso.
        resultado['dominio_ok'] = bool(dominio)
        resultado['valido'] = True
        resultado['mensagem'] = 'E-mail válido.' if dominio else 'Formato válido (domínio não verificado).'
        return resultado


class EnviadorEmail:
    """E-mails da recuperação de senha. Sem SMTP configurado, saem no console."""

    @staticmethod
    def _enviar(assunto: str, template: str, contexto: dict, para: str) -> bool:
        try:
            html = render_to_string(template, contexto)
            email = EmailMultiAlternatives(
                subject=assunto,
                body=strip_tags(html),
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[para],
            )
            email.attach_alternative(html, 'text/html')
            email.send()
            return True
        except Exception:
            logger.exception('Erro ao enviar e-mail "%s" para %s', assunto, para)
            return False

    @staticmethod
    def enviar_token_recuperacao(usuario, token_obj) -> bool:
        contexto = {
            'usuario': usuario.get_full_name() or usuario.username,
            'token': token_obj.token,
            'tempo_expiracao': 15,
            'link': f"{settings.FRONTEND_URL.rstrip('/')}/forgot-password",
        }
        ok = EnviadorEmail._enviar(
            'Código de recuperação de senha - MangeTech',
            'email/recuperacao_senha.html',
            contexto,
            token_obj.email_enviado_para,
        )
        if ok:
            logger.info('Código de recuperação enviado para %s', token_obj.email_enviado_para)
        return ok

    @staticmethod
    def enviar_confirmacao_resetar_senha(usuario) -> bool:
        contexto = {
            'usuario': usuario.get_full_name() or usuario.username,
            'link': f"{settings.FRONTEND_URL.rstrip('/')}/login",
        }
        return EnviadorEmail._enviar(
            'Sua senha foi alterada - MangeTech',
            'email/confirmacao_senha_resetada.html',
            contexto,
            usuario.email,
        )
