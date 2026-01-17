from Lexer.lexer import Lexer
from helpers.utils import Utils

from pathlib import Path

def run_lexer():

    # Chargement du fichier
    diagram = Path("../datas/test.drawio")
    xml_content = diagram.read_text("utf-8")

    # Creation du lexer
    lexer = Lexer(xml_content)

    # Execution
    result = lexer.execute()


    Utils.dump("../Lexer/result_lexer.json", result)

if __name__ == "__main__":
    run_lexer()
