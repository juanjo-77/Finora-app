using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FinanzasApi.Data;
using FinanzasApi.Models;

namespace FinanzasApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PresupuestosController : ControllerBase
{
    private readonly AppDbContext _db;
    public PresupuestosController(AppDbContext db) => _db = db;

    private int UsuarioId => int.Parse(User.FindFirst("sub")!.Value);

    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(await _db.Presupuestos
            .Where(p => p.UsuarioId == UsuarioId)
            .OrderBy(p => p.Categoria)
            .ToListAsync());

    [HttpPost]
    public async Task<IActionResult> Crear(Presupuesto presupuesto)
    {
        var existente = await _db.Presupuestos
            .FirstOrDefaultAsync(p => p.UsuarioId == UsuarioId && p.Categoria == presupuesto.Categoria);

        if (existente is not null)
        {
            existente.LimiteMensual = presupuesto.LimiteMensual;
            await _db.SaveChangesAsync();
            return Ok(existente);
        }

        presupuesto.UsuarioId = UsuarioId;
        _db.Presupuestos.Add(presupuesto);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetAll), presupuesto);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Eliminar(int id)
    {
        var p = await _db.Presupuestos.FirstOrDefaultAsync(x => x.Id == id && x.UsuarioId == UsuarioId);
        if (p is null) return NotFound();
        _db.Presupuestos.Remove(p);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}