using System.ComponentModel.DataAnnotations;
using FlowTask.Api.Models;
namespace FlowTask.Api.DTOs;
public record RegisterRequest([Required, MinLength(2)] string Name, [Required, EmailAddress] string Email, [Required, MinLength(6)] string Password);
public record LoginRequest([Required, EmailAddress] string Email, [Required] string Password);
public record AuthResponse(string Token, string Name, string Email);
public record TaskRequest([Required, MaxLength(120)] string Title, string? Description, string Category, TaskPriority Priority, DateTime? DueDate);
public record TaskResponse(int Id, string Title, string? Description, string Category, TaskPriority Priority, DateTime? DueDate, bool IsCompleted, DateTime CreatedAt);