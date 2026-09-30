namespace FinanzasApi.Models;

public class Presupuesto
{
    public int Id { get; set; }
    public int UsuarioId { get; set; }
    public string Categoria { get; set; } = string.Empty;
    public decimal LimiteMensual { get; set; }
}