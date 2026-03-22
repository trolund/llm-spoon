#!/usr/bin/env python3
import sys
import os
import argparse
import warnings
from pybars import Compiler
import openai
import cohere

try:
    from urllib3.exceptions import NotOpenSSLWarning
    warnings.filterwarnings("ignore", category=NotOpenSSLWarning)
except Exception:
    pass

compiler = Compiler()
script_dir = os.path.dirname(os.path.realpath(__file__))

def load_prompt(mode, text):
    prompt_path = os.path.join(script_dir, "prompts", f"{mode}.hbs")
    with open(prompt_path, "r") as f:
        template = compiler.compile(f.read())
    return template({"mode": mode, "text": text})

def extract_text(value):
    if value is None:
        return None
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        parts = [extract_text(item) for item in value]
        return "\n".join(part for part in parts if part)
    if isinstance(value, dict):
        for key in ("text", "output_text", "message", "content"):
            text = extract_text(value.get(key))
            if text:
                return text
        return None

    for key in ("text", "output_text", "message", "content"):
        if hasattr(value, key):
            text = extract_text(getattr(value, key))
            if text:
                return text

    return None

def call_openai(model, prompt, api_key):
    if hasattr(openai, "OpenAI"):
        client = openai.OpenAI(api_key=api_key)
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
        )
        return response.choices[0].message.content.strip()

    openai.api_key = api_key
    response = openai.ChatCompletion.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        temperature=0.7,
    )
    return response["choices"][0]["message"]["content"].strip()

def call_cohere(model, prompt, api_key):
    if hasattr(cohere, "ClientV2"):
        co = cohere.ClientV2(api_key=api_key)
        response = co.chat(
            model=model,
            message=prompt,
            temperature=0.7,
        )
        text = extract_text(response)
        if text:
            return text.strip()

    co = cohere.Client(api_key)
    if hasattr(co, "chat"):
        response = co.chat(
            model=model,
            message=prompt,
            temperature=0.7,
        )
        text = extract_text(response)
        if text:
            return text.strip()

    response = co.generate(
        model=model,
        prompt=prompt,
        temperature=0.7,
    )
    return response.generations[0].text.strip()

def load_text(args):
    if args.text is not None:
        return args.text
    if args.text_file is not None:
        with open(args.text_file, "r") as f:
            return f.read()
    return None

def format_error(err):
    code = getattr(err, "code", None)
    status_code = getattr(err, "status_code", None)
    message = str(err).strip() or err.__class__.__name__

    if code == "insufficient_quota" or "insufficient_quota" in message:
        return "OpenAI API quota exceeded. Add billing or use another API key."
    if status_code == 429:
        return "OpenAI rate limit exceeded. Retry later or use another API key."

    return message

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--provider", required=True)
    parser.add_argument("--model", required=True)
    parser.add_argument("--mode", required=True)
    text_group = parser.add_mutually_exclusive_group(required=True)
    text_group.add_argument("--text")
    text_group.add_argument("--text-file")
    args = parser.parse_args()

    api_key = os.environ.get("AIHELPER_API_KEY")
    if not api_key:
        sys.exit("Missing AIHELPER_API_KEY")

    prompt = load_prompt(args.mode, load_text(args))

    try:
        if args.provider == "openai":
            print(call_openai(args.model, prompt, api_key))
        elif args.provider == "cohere":
            print(call_cohere(args.model, prompt, api_key))
        else:
            sys.exit("Unsupported provider")
    except Exception as err:
        sys.stderr.write(format_error(err) + "\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
