"""
Serviço de Email para envio de tokens de recuperação
"""

import smtplib
import dns.resolver
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from django.conf import settings
from django.core.mail import send_mail, EmailMultiAlternatives
from django.template.loader import render_to_string
from django.utils.html import strip_tags
import logging

logger = logging.getLogger(__name__)


class VerificadorEmail:
    """Verifica se um email é real e válido"""
    
    @staticmethod
    def validar_sintaxe(email: str) -> bool:
        """Valida a sintaxe básica do email"""
        import re
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return re.match(pattern, email) is not None
    
    @staticmethod
    def validar_dominio(email: str) -> bool:
        """Valida se o domínio do email existe"""
        try:
            dominio = email.split('@')[1]
            # Tenta resolver o registro MX do domínio
            dns.resolver.resolve(dominio, 'MX')
            return True
        except Exception as e:
            logger.warning(f"Domínio inválido para {email}: {e}")
            return False
    
    @staticmethod
    def verificar_email_smtp(email: str) -> bool:
        """
        Verifica se o email existe via SMTP
        (Pode gerar falsos positivos dependendo do servidor)
        """
        try:
            dominio = email.split('@')[1]
            
            # Tentar conectar ao servidor SMTP
            smtp_server = smtplib.SMTP(timeout=5)
            smtp_server.connect(dominio)
            smtp_server.ehlo(smtp_server.local_hostname)
            
            # Verificar se o email existe
            code, message = smtp_server.vrfy(email)
            smtp_server.quit()
            
            # Code 250 = existe, 550 = não existe
            return code == 250
        except Exception as e:
            logger.warning(f"Erro ao verificar SMTP para {email}: {e}")
            # Se não conseguir verificar, considera como válido
            return True
    
    @staticmethod
    def verificar_email_completo(email: str) -> dict:
        """
        Verificação completa do email
        
        Returns:
            dict com resultado da verificação
        """
        resultado = {
            'email': email,
            'valido': False,
            'sintaxe_ok': False,
            'dominio_ok': False,
            'email_real': False,
            'mensagem': ''
        }
        
        # 1. Verificar sintaxe
        if not VerificadorEmail.validar_sintaxe(email):
            resultado['mensagem'] = 'Sintaxe de email inválida'
            return resultado
        
        resultado['sintaxe_ok'] = True
        
        # 2. Verificar domínio
        if not VerificadorEmail.validar_dominio(email):
            resultado['mensagem'] = 'Domínio não existe'
            return resultado
        
        resultado['dominio_ok'] = True
        
        # 3. Verificar SMTP
        if VerificadorEmail.verificar_email_smtp(email):
            resultado['email_real'] = True
            resultado['valido'] = True
            resultado['mensagem'] = 'Email válido e real'
        else:
            resultado['valido'] = False
            resultado['mensagem'] = 'Email não encontrado no servidor'
        
        return resultado


class EnviadorEmail:
    """Envia emails de recuperação de senha"""
    
    @staticmethod
    def enviar_token_recuperacao(usuario, token_obj):
        """
        Envia token de recuperação por email
        
        Args:
            usuario: Usuário Django
            token_obj: TokenRecuperacaoSenha
            
        Returns:
            True se enviado com sucesso
        """
        try:
            # Contexto para o template
            contexto = {
                'usuario': usuario.get_full_name() or usuario.username,
                'token': token_obj.token,
                'email': token_obj.email_enviado_para,
                'tempo_expiracao': 15,  # minutos
                'link_reset': f"{settings.FRONTEND_URL}/resetar-senha/{token_obj.token}",
            }
            
            # Renderizar template HTML
            html_message = render_to_string(
                'email/recuperacao_senha.html',
                contexto
            )
            
            # Versão em texto
            text_message = strip_tags(html_message)
            
            # Enviar email
            email = EmailMultiAlternatives(
                subject='🔐 Código de Recuperação de Senha - App Integrador',
                body=text_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[token_obj.email_enviado_para]
            )
            
            email.attach_alternative(html_message, "text/html")
            email.send()
            
            logger.info(f"Token de recuperação enviado para {token_obj.email_enviado_para}")
            return True
            
        except Exception as e:
            logger.error(f"Erro ao enviar email de recuperação: {e}")
            return False
    
    @staticmethod
    def enviar_confirmacao_resetar_senha(usuario, nova_senha):
        """
        Envia confirmação de que a senha foi resetada
        """
        try:
            contexto = {
                'usuario': usuario.get_full_name() or usuario.username,
                'email': usuario.email,
            }
            
            html_message = render_to_string(
                'email/confirmacao_senha_resetada.html',
                contexto
            )
            
            text_message = strip_tags(html_message)
            
            email = EmailMultiAlternatives(
                subject='Senha Resetada com Sucesso - App Integrador',
                body=text_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[usuario.email]
            )
            
            email.attach_alternative(html_message, "text/html")
            email.send()
            
            logger.info(f"Confirmação de reset enviada para {usuario.email}")
            return True
            
        except Exception as e:
            logger.error(f"Erro ao enviar confirmação: {e}")
            return False
        