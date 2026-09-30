namespace FinanzasApi.Models;

public enum TipoMovimiento { Ingreso, Gasto }

public class Movimiento
{
    public int Id { get; set; }
    public int UsuarioId { get; set; }
    public TipoMovimiento Tipo { get; set; }
    public string Categoria { get; set; } = string.Empty;
    public decimal Monto { get; set; }
    public DateTime Fecha { get; set; }
    public string? Nota { get; set; }
}