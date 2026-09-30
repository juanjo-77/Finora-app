using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FinanzasApi.Data;
using FinanzasApi.Models;

namespace FinanzasApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class InversionesController : ControllerBase
{
    private readonly AppDbContext _db;
    public InversionesController(AppDbContext db) => _db = db;

    private int UsuarioId => int.Parse(User.FindFirst("sub")!.Value);

    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(await _db.Inversiones
            .Where(i => i.UsuarioId == UsuarioId)
            .OrderByDescending(i => i.ValorActual)
            .ToListAsync());

    [HttpPost]
    public async Task<IActionResult> Create(Inversion inversion)
    {
        inversion.UsuarioId = UsuarioId;
        _db.Inversiones.Add(inversion);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetAll), inversion);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, Inversion inversion)
    {
        var existente = await _db.Inversiones.FirstOrDefaultAsync(i => i.Id == id && i.UsuarioId == UsuarioId);
        if (existente is null) return NotFound();

        existente.Nombre = inversion.Nombre;
        existente.Tipo = inversion.Tipo;
        existente.MontoInvertido = inversion.MontoInvertido;
        existente.ValorActual = inversion.ValorActual;

        await _db.SaveChangesAsync();
        return Ok(existente);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var i = await _db.Inversiones.FirstOrDefaultAsync(x => x.Id == id && x.UsuarioId == UsuarioId);
        if (i is null) return NotFound();
        _db.Inversiones.Remove(i);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}