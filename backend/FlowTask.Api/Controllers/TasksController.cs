using System.Security.Claims;
using FlowTask.Api.Data;
using FlowTask.Api.DTOs;
using FlowTask.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace FlowTask.Api.Controllers;
[Authorize, ApiController, Route("api/tasks")]
public class TasksController(AppDbContext db) : ControllerBase {
  int UserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
  [HttpGet]
  public async Task<ActionResult<IEnumerable<TaskResponse>>> List([FromQuery] bool? completed, [FromQuery] TaskPriority? priority, [FromQuery] string? category, [FromQuery] string? search) {
    var query = db.Tasks.AsNoTracking().Where(x => x.UserId == UserId);
    if (completed.HasValue) query = query.Where(x => x.IsCompleted == completed);
    if (priority.HasValue) query = query.Where(x => x.Priority == priority);
    if (!string.IsNullOrWhiteSpace(category)) query = query.Where(x => x.Category == category);
    if (!string.IsNullOrWhiteSpace(search)) query = query.Where(x => x.Title.Contains(search));
    return Ok(await query.OrderBy(x => x.IsCompleted).ThenBy(x => x.DueDate).Select(x =>
      new TaskResponse(x.Id, x.Title, x.Description, x.Category, x.Priority, x.DueDate, x.IsCompleted, x.CreatedAt)).ToListAsync());
  }
  [HttpPost]
  public async Task<ActionResult<TaskResponse>> Create(TaskRequest req) {
    var item = new TaskItem { Title=req.Title.Trim(), Description=req.Description, Category=req.Category, Priority=req.Priority, DueDate=req.DueDate, UserId=UserId };
    db.Tasks.Add(item); await db.SaveChangesAsync();
    return CreatedAtAction(nameof(Get), new { id=item.Id }, Map(item));
  }
  [HttpGet("{id:int}")]
  public async Task<ActionResult<TaskResponse>> Get(int id) {
    var item = await db.Tasks.AsNoTracking().SingleOrDefaultAsync(x => x.Id==id && x.UserId==UserId);
    return item is null ? NotFound() : Ok(Map(item));
  }
  [HttpPut("{id:int}")]
  public async Task<ActionResult<TaskResponse>> Update(int id, TaskRequest req) {
    var item = await db.Tasks.SingleOrDefaultAsync(x => x.Id==id && x.UserId==UserId);
    if (item is null) return NotFound();
    item.Title=req.Title.Trim(); item.Description=req.Description; item.Category=req.Category; item.Priority=req.Priority; item.DueDate=req.DueDate;
    await db.SaveChangesAsync(); return Ok(Map(item));
  }
  [HttpPatch("{id:int}/toggle")]
  public async Task<ActionResult<TaskResponse>> Toggle(int id) {
    var item = await db.Tasks.SingleOrDefaultAsync(x => x.Id==id && x.UserId==UserId);
    if (item is null) return NotFound();
    item.IsCompleted=!item.IsCompleted; await db.SaveChangesAsync(); return Ok(Map(item));
  }
  [HttpDelete("{id:int}")]
  public async Task<IActionResult> Delete(int id) {
    var item = await db.Tasks.SingleOrDefaultAsync(x => x.Id==id && x.UserId==UserId);
    if (item is null) return NotFound();
    db.Tasks.Remove(item); await db.SaveChangesAsync(); return NoContent();
  }
  static TaskResponse Map(TaskItem x) => new(x.Id,x.Title,x.Description,x.Category,x.Priority,x.DueDate,x.IsCompleted,x.CreatedAt);
}