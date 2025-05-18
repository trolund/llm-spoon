#!/usr/bin/env python3
import cohere
import sys
import os

api_key = os.environ.get("COHERE_API_KEY")
text = os.environ.get("TEXT")

print("Using API key:", api_key, file=sys.stderr)

if not api_key:
    print("Missing COHERE_API_KEY environment variable", file=sys.stderr)
    sys.exit(1)


print("Input text length:", len(text), file=sys.stderr)

if not text:
    print("Input text is empty", file=sys.stderr)
    sys.exit(1)

co = cohere.Client(api_key)

prompt = f"Please rewrite this text to improve clarity, grammar, and flow. Please only provide the improved text. The text will either be in english or danish. Input:\n\n{text}"

response = co.generate(
    model='command-r-plus',
    prompt=prompt,
    temperature=0.7,
)

print(response.generations[0].text.strip())
