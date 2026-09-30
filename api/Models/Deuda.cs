namespace FinanzasApi.Models;

public class Deuda
{
    public int Id { get; set; }
    public int UsuarioId { get; set; }
    public string Nombre { get; set; } = string.Empty;      // "Tarjeta de crédito", "Préstamo estudiantil"
    public decimal MontoTotal { get; set; }                  // deuda total restante
    public decimal CuotaMensual { get; set; }                 // cuánto pagas cada mes
    public DateTime ProximaFecha { get; set; }                 // próxima fecha de pago
    public decimal? TasaInteres { get; set; }                 // opcional, % anual
    public bool Activa { get; set; } = true;
}