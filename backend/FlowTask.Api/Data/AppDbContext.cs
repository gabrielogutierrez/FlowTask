using FlowTask.Api.Models;
using Microsoft.EntityFrameworkCore;
namespace FlowTask.Api.Data;
public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options) {
  public DbSet<User> Users => Set<User>();
  public DbSet<TaskItem> Tasks => Set<TaskItem>();
  protected override void OnModelCreating(ModelBuilder b) {
    b.Entity<User>().HasIndex(x => x.Email).IsUnique();
    b.Entity<TaskItem>().HasOne(x => x.User).WithMany(x => x.Tasks).HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
  }
}