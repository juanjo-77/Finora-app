using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FinanzasApi.Data;
using FinanzasApi.Models;

namespace FinanzasApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class MetasController : ControllerBase
{
    private readonly AppDbContext _db;
    public MetasController(AppDbContext db) => _db = db;

    private int UsuarioId => int.Parse(User.FindFirst("sub")!.Value);

    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(await _db.Metas
            .Where(m => m.UsuarioId == UsuarioId)
            .OrderBy(m => m.Nombre)
            .ToListAsync());

    [HttpPost]
    public async Task<IActionResult> Create(Meta meta)
    {
        if (meta.MontoAhorrado > meta.MontoObjetivo)
            return BadRequest(new { mensaje = "Lo ahorrado no puede superar el monto objetivo." });

        meta.UsuarioId = UsuarioId;
        _db.Metas.Add(meta);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetAll), meta);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, Meta meta)
    {
        if (meta.MontoAhorrado > meta.MontoObjetivo)
            return BadRequest(new { mensaje = "Lo ahorrado no puede superar el monto objetivo." });

        var existente = await _db.Metas.FirstOrDefaultAsync(m => m.Id == id && m.UsuarioId == UsuarioId);
        if (existente is null) return NotFound();

        existente.Nombre = meta.Nombre;
        existente.MontoObjetivo = meta.MontoObjetivo;
        existente.MontoAhorrado = meta.MontoAhorrado;
        existente.AhorroMensualPlaneado = meta.AhorroMensualPlaneado;

        await _db.SaveChangesAsync();
        return Ok(existente);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var m = await _db.Metas.FirstOrDefaultAsync(x => x.Id == id && x.UsuarioId == UsuarioId);
        if (m is null) return NotFound();
        _db.Metas.Remove(m);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}