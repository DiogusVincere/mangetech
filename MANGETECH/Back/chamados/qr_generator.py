"""Geração do QR code dos ativos (PNG), com etiqueta de código e nome embaixo."""

import base64
from io import BytesIO

import qrcode
from PIL import Image, ImageDraw, ImageFont


class QRCodeGenerator:
    BOX_SIZE = 10
    BORDER = 4

    @staticmethod
    def gerar_qr_codigo(dados: str) -> Image.Image:
        qr = qrcode.QRCode(
            version=None,  # tamanho automático conforme o conteúdo
            error_correction=qrcode.constants.ERROR_CORRECT_H,
            box_size=QRCodeGenerator.BOX_SIZE,
            border=QRCodeGenerator.BORDER,
        )
        qr.add_data(dados)
        qr.make(fit=True)
        return qr.make_image(fill_color='black', back_color='white').convert('RGB')

    @staticmethod
    def _fonte(tamanho: int):
        for nome in ('DejaVuSans-Bold.ttf', 'arialbd.ttf', 'Arial Bold.ttf', 'DejaVuSans.ttf', 'arial.ttf'):
            try:
                return ImageFont.truetype(nome, tamanho)
            except OSError:
                continue
        try:
            return ImageFont.load_default(size=tamanho)
        except TypeError:  # Pillow antigo
            return ImageFont.load_default()

    @staticmethod
    def gerar_qr_com_label(dados: str, label: str | None = None) -> Image.Image:
        qr_img = QRCodeGenerator.gerar_qr_codigo(dados)
        if not label:
            return qr_img

        linhas = [linha for linha in str(label).splitlines() if linha.strip()]
        fonte = QRCodeGenerator._fonte(22)
        medidor = ImageDraw.Draw(qr_img)
        largura_max = qr_img.width - 20

        # Corta linhas longas para caber na largura do QR.
        ajustadas = []
        for linha in linhas:
            while len(linha) > 1 and medidor.textlength(linha, font=fonte) > largura_max:
                linha = linha.rstrip('…')[:-1] + '…'
            ajustadas.append(linha)

        altura_linha = 30
        nova = Image.new('RGB', (qr_img.width, qr_img.height + altura_linha * len(ajustadas) + 10), 'white')
        nova.paste(qr_img, (0, 0))
        draw = ImageDraw.Draw(nova)
        y = qr_img.height - 8
        for linha in ajustadas:
            largura = draw.textlength(linha, font=fonte)
            draw.text(((nova.width - largura) / 2, y), linha, fill='black', font=fonte)
            y += altura_linha
        return nova

    @staticmethod
    def gerar_png(dados: str, label: str | None = None) -> bytes:
        img = QRCodeGenerator.gerar_qr_com_label(dados, label)
        buffer = BytesIO()
        img.save(buffer, format='PNG')
        return buffer.getvalue()

    @staticmethod
    def gerar_qr_base64(dados: str, label: str | None = None) -> str:
        return base64.b64encode(QRCodeGenerator.gerar_png(dados, label)).decode()
