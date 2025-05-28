#!/usr/bin/env python3
import sys
import os
import argparse
from pybars import Compiler
import openai
import cohere

compiler = Compiler()
script_dir = os.path.dirname(os.path.realpath(__file__))

def load_prompt(mode, text):
    prompt_path = os.path.join(script_dir, "prompts", f"{mode}.hbs")
    with open(prompt_path, "r") as f:
        template = compiler.compile(f.read())
    return template({"mode": mode, "text": text})

def call_openai(model, prompt, api_key):
    openai.api_key = api_key
    response = openai.ChatCompletion.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        temperature=0.7
    )
    return response['choices'][0]['message']['content'].strip()

def call_cohere(model, prompt, api_key):
    co = cohere.Client(api_key)
    response = co.generate(
        model=model,
        prompt=prompt,
        temperature=0.7
    )
    return response.generations[0].text.strip()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--provider", required=True)
    parser.add_argument("--model", required=True)
    parser.add_argument("--mode", required=True)
    parser.add_argument("--text", required=True)
    args = parser.parse_args()

    api_key = os.environ.get("AIHELPER_API_KEY")
    if not api_key:
        sys.exit("Missing AIHELPER_API_KEY")

    prompt = load_prompt(args.mode, args.text)

    if args.provider == "openai":
        print(call_openai(args.model, prompt, api_key))
    elif args.provider == "cohere":
        print(call_cohere(args.model, prompt, api_key))
    else:
        sys.exit("Unsupported provider")

if __name__ == "__main__":
    main()
