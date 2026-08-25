namespace FlowTask.Api.Models;
public enum TaskPriority { Low, Medium, High }
public class TaskItem {
  public int Id { get; set; }
  public required string Title { get; set; }
  public string? Description { get; set; }
  public string Category { get; set; } = "Geral";
  public TaskPriority Priority { get; set; } = TaskPriority.Medium;
  public DateTime? DueDate { get; set; }
  public bool IsCompleted { get; set; }
  public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
  public int UserId { get; set; }
  public User? User { get; set; }
}