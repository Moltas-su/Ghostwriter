# GhostWriter

GhostWriter brings back the classic right click writing tools on macOS. Highlight text in any application, choose Proofread or Rewrite from the Services menu, and GhostWriter replaces your text directly where you typed it.

### How it works

GhostWriter runs in the background from your menu bar. When you select text and trigger an action, it routes your request through one of two backends:

1. Apple Shortcuts. This uses your system Shortcuts app to tap into native Apple Intelligence.
2. Local models. This runs Gemma locally on your machine using Metal GPU acceleration, keeping everything private and offline.

You can pick which backend you prefer from the settings window. Local models can be downloaded directly inside the app.

### How to use it

Launch GhostWriter and walk through the setup guide.

Once you are done with setup, highlight any editable text in any app. Right click and open the Services menu. You will find two items:

1. GhostWriter Proofread
2. GhostWriter Rewrite

Select the one you want for the task you want GhostWriter to perform, and it will update your text in place.

### Project status

GhostWriter is currently in beta. It is actively being improved and refined.

Some of the code in this project was written with AI assistance.

### Building from source

If you want to compile GhostWriter yourself, you need an Apple Silicon Mac running macOS 14 Sonoma or later.

Optional dependencies for local model support:

```bash
brew install llama.cpp dylibbundler
```

Compile and install:

```bash
make
```

The build script compiles the Swift sources, bundles the dependencies, and places GhostWriter inside your Applications folder.
