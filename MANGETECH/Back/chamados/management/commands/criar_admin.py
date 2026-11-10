"""
Cria o primeiro administrador a partir de variáveis de ambiente.

    ADMIN_EMAIL=voce@exemplo.com ADMIN_PASSWORD=... python manage.py criar_admin

Pensado para rodar a cada início do servidor (o Render gratuito não tem
terminal para um createsuperuser): sem ADMIN_EMAIL, não faz nada; se o usuário
já existe, só garante que ele é administrador e ativo, sem mexer na senha
(trocas feitas depois pelo perfil continuam valendo).
"""

import os

from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = 'Cria (uma vez) o administrador definido em ADMIN_EMAIL / ADMIN_PASSWORD.'

    def handle(self, *args, **options):
        email = os.environ.get('ADMIN_EMAIL', '').strip().lower()
        if not email:
            self.stdout.write('ADMIN_EMAIL não definido: nenhum administrador criado.')
            return

        user = User.objects.filter(email__iexact=email).first() or User.objects.filter(username__iexact=email).first()
        if user:
            if not (user.is_staff and user.is_superuser and user.is_active):
                user.is_staff = user.is_superuser = user.is_active = True
                user.save(update_fields=['is_staff', 'is_superuser', 'is_active'])
            self.stdout.write(f'Administrador {email} já existe; senha mantida.')
            return

        senha = os.environ.get('ADMIN_PASSWORD', '')
        nome = ' '.join(os.environ.get('ADMIN_NOME', '').split())
        partes = nome.split(' ', 1) if nome else ['Administrador']
        novo = User(
            username=email,
            email=email,
            first_name=partes[0][:150],
            last_name=(partes[1] if len(partes) > 1 else '')[:150],
            is_staff=True,
            is_superuser=True,
        )
        try:
            validate_password(senha, novo)
        except ValidationError as exc:
            raise CommandError('ADMIN_PASSWORD fraca ou vazia: ' + ' '.join(exc.messages))
        novo.set_password(senha)
        novo.save()
        self.stdout.write(self.style.SUCCESS(f'Administrador {email} criado.'))
