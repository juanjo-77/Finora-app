using Microsoft.EntityFrameworkCore;
using FinanzasApi.Models;

namespace FinanzasApi.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) {}

    public DbSet<Usuario> Usuarios => Set<Usuario>();
    public DbSet<Movimiento> Movimientos => Set<Movimiento>();
    public DbSet<Deuda> Deudas => Set<Deuda>();
    public DbSet<Presupuesto> Presupuestos => Set<Presupuesto>();
    public DbSet<Inversion> Inversiones => Set<Inversion>();
        public DbSet<Meta> Metas => Set<Meta>();
}