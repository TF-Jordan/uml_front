from typing import Any, Dict, List, Optional, Union
import json


class Utils:
    @staticmethod
    def lowercase_keys(data: Union[dict[Any, Any], list[Any]]) -> Union[dict[Any, Any], list[Any], Any]:
        if isinstance(data, dict):
            return {
                k.lower() if isinstance(k, str) else k: Utils.lowercase_keys(v)
                for k, v in data.items()
            }
        elif isinstance(data, list):
            return [Utils.lowercase_keys(item) for item in data]
        else:
            return data

    @staticmethod
    def dump(file_path, data):
        with open(file_path, 'w', encoding="utf-8") as f:
            json.dump(data, f, indent=4, ensure_ascii=False)

    @staticmethod
    def snake_to_pascal(snake_str):
        return Utils.capitalize(''.join(Utils.capitalize(word) for word in snake_str.split('_')))

    @staticmethod
    def capitalize(input_str: str):
        if input_str == "":
            return input_str
        return input_str[0].upper() + input_str[1:]

    @staticmethod
    def parse_class_descriptor(descriptor: Any) -> Dict[str, Any]:
        """
        Parse the legacy `type` descriptor (e.g. 'class, extends Foo, implements Bar') and
        extract a normalized class role, extends target and implemented interfaces.
        """
        result = {"class_type": "class", "extends": None, "implements": []}
        raw_value = str(descriptor or "").strip()
        if not raw_value:
            return result
        segments = [segment.strip() for segment in raw_value.split(",") if segment.strip()]
        if not segments:
            return result
        base_segment = segments[0].lower()
        if "interface" in base_segment:
            result["class_type"] = "interface"
        elif "abstract" in base_segment:
            result["class_type"] = "abstract"
        else:
            result["class_type"] = "class"

        for segment in segments[1:]:
            lower = segment.lower()
            if lower.startswith("extends"):
                extends_value = segment[len("extends") :].strip()
                if extends_value:
                    result["extends"] = extends_value
            elif lower.startswith("implements"):
                implements_value = segment[len("implements") :].strip()
                if implements_value:
                    for item in implements_value.split(","):
                        item_norm = item.strip()
                        if item_norm:
                            result["implements"].append(item_norm)
        return result
