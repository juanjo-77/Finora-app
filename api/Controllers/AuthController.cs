using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Google.Apis.Auth;
using FinanzasApi.Data;
using FinanzasApi.Models;

namespace FinanzasApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IConfiguration _config;

    public AuthController(AppDbContext db, IConfiguration config)
    {
        _db = db;
        _config = config;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterRequest req)
    {
        if (await _db.Usuarios.AnyAsync(u => u.Email == req.Email))
            return BadRequest(new { mensaje = "Ese correo ya está registrado." });

        var usuario = new Usuario
        {
            Email = req.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password)
        };
        _db.Usuarios.Add(usuario);
        await _db.SaveChangesAsync();

        return Ok(new AuthResponse(GenerarToken(usuario), usuario.Email));
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest req)
    {
        var usuario = await _db.Usuarios.FirstOrDefaultAsync(u => u.Email == req.Email);
        if (usuario is null || !BCrypt.Net.BCrypt.Verify(req.Password, usuario.PasswordHash))
            return Unauthorized(new { mensaje = "Correo o contraseña incorrectos." });

        return Ok(new AuthResponse(GenerarToken(usuario), usuario.Email));
    }

    [HttpPost("google")]
    public async Task<IActionResult> GoogleLogin(GoogleLoginRequest req)
    {
        GoogleJsonWebSignature.Payload payload;
        try
        {
            payload = await GoogleJsonWebSignature.ValidateAsync(req.IdToken, new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = new[] { _config["Google:ClientId"] }
            });
        }
        catch (InvalidJwtException)
        {
            return Unauthorized(new { mensaje = "Token de Google inválido." });
        }

        var usuario = await _db.Usuarios.FirstOrDefaultAsync(u => u.Email == payload.Email);
        if (usuario is null)
        {
            usuario = new Usuario
            {
                Email = payload.Email,
                // Cuentas de Google no usan contraseña local; guardamos un hash aleatorio que nunca se usa.
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString())
            };
            _db.Usuarios.Add(usuario);
            await _db.SaveChangesAsync();
        }

        return Ok(new AuthResponse(GenerarToken(usuario), usuario.Email));
    }

    private string GenerarToken(Usuario usuario)
    {
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, usuario.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, usuario.Email),
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddDays(7),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}