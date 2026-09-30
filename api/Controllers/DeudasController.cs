using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FinanzasApi.Data;
using FinanzasApi.Models;

namespace FinanzasApi.Controllers;

public record AbonoRequest(decimal Monto);

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DeudasController : ControllerBase
{
    private readonly AppDbContext _db;
    public DeudasController(AppDbContext db) => _db = db;

    private int UsuarioId => int.Parse(User.FindFirst("sub")!.Value);

    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(await _db.Deudas
            .Where(d => d.UsuarioId == UsuarioId && d.Activa)
            .OrderBy(d => d.ProximaFecha)
            .ToListAsync());

    [HttpPost]
    public async Task<IActionResult> Create(Deuda deuda)
    {
        deuda.UsuarioId = UsuarioId;
        deuda.ProximaFecha = DateTime.SpecifyKind(deuda.ProximaFecha, DateTimeKind.Utc);
        _db.Deudas.Add(deuda);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetAll), deuda);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, Deuda deuda)
    {
        var existente = await _db.Deudas.FirstOrDefaultAsync(d => d.Id == id && d.UsuarioId == UsuarioId);
        if (existente is null) return NotFound();

        existente.Nombre = deuda.Nombre;
        existente.MontoTotal = deuda.MontoTotal;
        existente.CuotaMensual = deuda.CuotaMensual;
        existente.ProximaFecha = DateTime.SpecifyKind(deuda.ProximaFecha, DateTimeKind.Utc);
        existente.TasaInteres = deuda.TasaInteres;

        await _db.SaveChangesAsync();
        return Ok(existente);
    }

    [HttpPost("{id}/abonar")]
    public async Task<IActionResult> Abonar(int id, AbonoRequest abono)
    {
        if (abono.Monto <= 0) return BadRequest(new { mensaje = "El abono debe ser mayor a cero." });

        var existente = await _db.Deudas.FirstOrDefaultAsync(d => d.Id == id && d.UsuarioId == UsuarioId);
        if (existente is null) return NotFound();

        if (abono.Monto > existente.MontoTotal)
            return BadRequest(new { mensaje = $"El abono no puede superar el saldo pendiente ({existente.MontoTotal:C0})." });

        existente.MontoTotal -= abono.Monto;

        if (existente.MontoTotal == 0)
        {
            existente.Activa = false;
        }

        await _db.SaveChangesAsync();
        return Ok(existente);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var d = await _db.Deudas.FirstOrDefaultAsync(x => x.Id == id && x.UsuarioId == UsuarioId);
        if (d is null) return NotFound();
        _db.Deudas.Remove(d);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}