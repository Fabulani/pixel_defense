# Particles are never pooled or cached

- **Type:** performance
- **Priority:** low (measure first)
- **Area:** VFX

Every bullet trail, muzzle flash and burst creates its own `GPUParticles2D` and `ParticleProcessMaterial`, and every smoking, regenerating or dashing enemy adds continuous emitters. Measure on Android and Web in late waves before optimising. If needed, cache the materials per colour or kind, pool the burst nodes in `VfxManager`, or switch `make_particles()` to `CPUParticles2D` (a one-function change).
