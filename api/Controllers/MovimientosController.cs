using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FinanzasApi.Data;
using FinanzasApi.Models;

namespace FinanzasApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class MovimientosController : ControllerBase
{
    private readonly AppDbContext _db;
    public MovimientosController(AppDbContext db) => _db = db;

    private int UsuarioId => int.Parse(User.FindFirst("sub")!.Value);

    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(await _db.Movimientos
            .Where(m => m.UsuarioId == UsuarioId)
            .OrderByDescending(m => m.Fecha)
            .ToListAsync());

    [HttpPost]
    public async Task<IActionResult> Create(Movimiento movimiento)
    {
        movimiento.UsuarioId = UsuarioId;
        movimiento.Fecha = DateTime.SpecifyKind(movimiento.Fecha, DateTimeKind.Utc);
        _db.Movimientos.Add(movimiento);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetAll), movimiento);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var m = await _db.Movimientos.FirstOrDefaultAsync(x => x.Id == id && x.UsuarioId == UsuarioId);
        if (m is null) return NotFound();
        _db.Movimientos.Remove(m);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}