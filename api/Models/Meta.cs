namespace FinanzasApi.Models;

public class Meta
{
    public int Id { get; set; }
    public int UsuarioId { get; set; }
    public string Nombre { get; set; } = string.Empty;       // "Fondo de emergencia", "Computador"
    public decimal MontoObjetivo { get; set; }
    public decimal MontoAhorrado { get; set; }
    public decimal AhorroMensualPlaneado { get; set; }         // cuánto piensas ahorrarle al mes
}