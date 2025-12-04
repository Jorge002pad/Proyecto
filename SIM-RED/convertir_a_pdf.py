#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para convertir el documento Word a PDF
"""

from docx2pdf import convert
import os

def convert_to_pdf():
    """Convierte el documento Word a PDF"""
    input_file = 'presentacion_simred.docx'
    output_file = 'presentacion_simred.pdf'
    
    if not os.path.exists(input_file):
        print(f"❌ Error: No se encuentra el archivo {input_file}")
        return False
    
    try:
        print(f"🔄 Convirtiendo {input_file} a PDF...")
        convert(input_file, output_file)
        print(f"✅ PDF creado exitosamente: {output_file}")
        return True
    except Exception as e:
        print(f"❌ Error al convertir a PDF: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == '__main__':
    convert_to_pdf()
