from Lexer.run_lexer import Lexer
from pathlib import Path
from Parser.parser import Parser

from helpers.utils import Utils

def run_parser():

    # Chargement du fichier
    diagram = Path("../datas/test.drawio")
    xml_content = diagram.read_text("utf-8")

    print("1")
    # Creation du lexer
    lexer = Lexer(xml_content)

    print("2")
    # Execution
    token = lexer.execute()

    print ("bonjour")
    parser = Parser(token)

    print ("bonjour")
    result = parser.execute()

    Utils.dump("../Parser/result_parser.json", result)


if __name__ == "__main__":
    run_parser()