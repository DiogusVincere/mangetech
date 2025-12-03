import qrcode
from io import BytesIO
import base64
from PIL import Image, ImageDraw
from django.conf import settings
import os


class QRCodeGenerator:
    """Gera QR Codes para ativos de forma profissional"""
    
    # Configurações
    QR_VERSION = 1  # Tamanho automático
    QR_BOX_SIZE = 10  # Pixels por box do QR
    QR_BORDER = 4  # Número de boxes de borda
    QR_FILL_COLOR = "black"
    QR_BACK_COLOR = "white"
    
    @staticmethod
    def gerar_qr_codigo(dados: str, incluir_logo: bool = False) -> Image.Image:
        """
        Gera um QR code a partir dos dados fornecidos
        
        Args:
            dados: Dados a codificar no QR (ex: código do ativo)
            incluir_logo: Se deve incluir um logo no centro
            
        Returns:
            Image PIL com o QR code gerado
        """
        qr = qrcode.QRCode(
            version=QRCodeGenerator.QR_VERSION,
            error_correction=qrcode.constants.ERROR_CORRECT_H,
            box_size=QRCodeGenerator.QR_BOX_SIZE,
            border=QRCodeGenerator.QR_BORDER,
        )
        
        qr.add_data(dados)
        qr.make(fit=True)
        
        # Gerar imagem
        img = qr.make_image(
            fill_color=QRCodeGenerator.QR_FILL_COLOR,
            back_color=QRCodeGenerator.QR_BACK_COLOR,
        )
        
        return img
    
    @staticmethod
    def gerar_qr_com_label(
        dados: str,
        label: str = None,
        tamanho_label: int = 20
    ) -> Image.Image:
        """
        Gera QR code com label abaixo
        
        Args:
            dados: Dados do QR code
            label: Texto a exibir abaixo do QR
            tamanho_label: Altura reservada para o label
            
        Returns:
            Image PIL com QR code e label
        """
        # Gerar QR code
        qr_img = QRCodeGenerator.gerar_qr_codigo(dados)
        
        if not label:
            return qr_img
        
        # Criar imagem com espaço para label
        label_height = tamanho_label + 20
        nova_img = Image.new(
            'RGB',
            (qr_img.width, qr_img.height + label_height),
            'white'
        )
        
        # Colar QR code
        nova_img.paste(qr_img, (0, 0))
        
        # Adicionar label
        draw = ImageDraw.Draw(nova_img)
        
        # Calcular posição do texto (centralizado)
        text_width = draw.textlength(label)
        x_pos = (nova_img.width - text_width) / 2
        y_pos = qr_img.height + 5
        
        # Desenhar texto
        draw.text(
            (x_pos, y_pos),
            label,
            fill='black'
        )
        
        return nova_img
    
    @staticmethod
    def gerar_qr_base64(
        dados: str,
        label: str = None,
        com_label: bool = False
    ) -> str:
        """
        Gera QR code e retorna como string base64
        
        Args:
            dados: Dados do QR code
            label: Label opcional
            com_label: Se deve incluir label
            
        Returns:
            String base64 da imagem
        """
        if com_label and label:
            img = QRCodeGenerator.gerar_qr_com_label(dados, label)
        else:
            img = QRCodeGenerator.gerar_qr_codigo(dados)
        
        # Converter para bytes
        buffer = BytesIO()
        img.save(buffer, format='PNG')
        buffer.seek(0)
        
        # Retornar como base64
        return base64.b64encode(buffer.getvalue()).decode()
    
    @staticmethod
    def salvar_qr_arquivo(
        dados: str,
        caminho: str,
        label: str = None,
        com_label: bool = False
    ) -> bool:
        """
        Salva QR code em arquivo
        
        Args:
            dados: Dados do QR code
            caminho: Caminho do arquivo
            label: Label opcional
            com_label: Se deve incluir label
            
        Returns:
            True se salvou com sucesso
        """
        try:
            if com_label and label:
                img = QRCodeGenerator.gerar_qr_com_label(dados, label)
            else:
                img = QRCodeGenerator.gerar_qr_codigo(dados)
            
            # Criar diretório se não existir
            os.makedirs(os.path.dirname(caminho), exist_ok=True)
            
            # Salvar
            img.save(caminho)
            return True
        except Exception as e:
            print(f"Erro ao salvar QR code: {e}")
            return False


# ========== SERIALIZERS COM QR CODE ==========

class QRCodeSerializer:
    """Serializer para QR codes"""
    
    @staticmethod
    def get_qr_base64(ativo_codigo: str) -> str:
        """Retorna QR code em base64"""
        return QRCodeGenerator.gerar_qr_base64(ativo_codigo)
    
    @staticmethod
    def get_qr_com_label(ativo_codigo: str, ativo_nome: str = None) -> str:
        """Retorna QR code com label em base64"""
        label = f"{ativo_codigo}\n{ativo_nome}" if ativo_nome else ativo_codigo
        return QRCodeGenerator.gerar_qr_base64(
            ativo_codigo,
            label=label,
            com_label=True
        )





