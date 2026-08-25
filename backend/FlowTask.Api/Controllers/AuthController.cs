using FlowTask.Api.Data;
using FlowTask.Api.DTOs;
using FlowTask.Api.Models;
using FlowTask.Api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace FlowTask.Api.Controllers;
[ApiController, Route("api/auth")]
public class AuthController(AppDbContext db, PasswordService passwords, TokenService tokens) : ControllerBase {
  [HttpPost("register")]
  public async Task<ActionResult<AuthResponse>> Register(RegisterRequest req) {
    var email = req.Email.Trim().ToLowerInvariant();
    if (await db.Users.AnyAsync(x => x.Email == email)) return Conflict(new { message = "E-mail já cadastrado." });
    var user = new User { Name = req.Name.Trim(), Email = email, PasswordHash = passwords.Hash(req.Password) };
    db.Users.Add(user); await db.SaveChangesAsync();
    return Ok(new AuthResponse(tokens.Create(user), user.Name, user.Email));
  }
  [HttpPost("login")]
  public async Task<ActionResult<AuthResponse>> Login(LoginRequest req) {
    var user = await db.Users.SingleOrDefaultAsync(x => x.Email == req.Email.Trim().ToLower());
    if (user is null || !passwords.Verify(req.Password, user.PasswordHash)) return Unauthorized(new { message = "Credenciais inválidas." });
    return Ok(new AuthResponse(tokens.Create(user), user.Name, user.Email));
  }
}