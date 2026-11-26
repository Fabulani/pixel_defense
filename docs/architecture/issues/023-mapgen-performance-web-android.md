# Measure map generation time on Web and Android

- **Type:** performance
- **Priority:** low
- **Area:** map generation

Generation takes about 215 ms per map in a headless desktop run (about 1.3 attempts on average; shape cleanup and decor are the slowest parts). It has not been measured on Web or Android, where it could cause a noticeable hitch on start, restart and F1. Measure first; optimise or spread it over frames (or add a loading tell) only if needed.
