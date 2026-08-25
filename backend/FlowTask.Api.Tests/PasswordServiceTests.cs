using FlowTask.Api.Services;
using Xunit;
namespace FlowTask.Api.Tests;
public class PasswordServiceTests {
  [Fact]
  public void HashAndVerifyValidPassword() {
    var service = new PasswordService();
    var hash = service.Hash("segredo123");
    Assert.True(service.Verify("segredo123", hash));
    Assert.False(service.Verify("errada", hash));
  }
}