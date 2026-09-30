namespace FinanzasApi.Models;

public class Inversion
{
    public int Id { get; set; }
    public int UsuarioId { get; set; }
    public string Nombre { get; set; } = string.Empty;      // "S&P 500", "CDT Bancolombia"
    public string Tipo { get; set; } = string.Empty;         // "Acciones", "ETF", "Fondo", "CDT", "Cripto", "Otro"
    public decimal MontoInvertido { get; set; }               // lo que has puesto en total
    public decimal ValorActual { get; set; }                  // cuánto vale hoy
}