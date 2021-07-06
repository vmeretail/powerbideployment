using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PowerBIReleaseProcess
{
    using System.Net.Http;
    using System.Net.Http.Headers;
    using System.Threading;
    using Newtonsoft.Json;

    public interface IGitHubService
    {
        Task<(String releaseId, String body)> GetReleaseFromTag(String tag, CancellationToken cancellationToken);


        Task UpdateRelease(String releaseId, String releaseBody, CancellationToken cancellationToken);
    }

    public class GitHubService : IGitHubService
    {
        private readonly String GithubApiUrl;

        private readonly String Token;

        private readonly HttpClient HttpClient;
        public GitHubService(String githubApiUrl, String token)
        {
            this.GithubApiUrl = githubApiUrl;
            this.Token = token;
            this.HttpClient = new HttpClient();
        }

        public async Task<(String releaseId, String body)> GetReleaseFromTag(String tag,
                                          CancellationToken cancellationToken)
        {
            String requestUri = $"{this.GithubApiUrl}/releases/tags/{tag}";
            HttpRequestMessage requestMessage = new HttpRequestMessage(HttpMethod.Get, requestUri);
            requestMessage.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/vnd.github.v3+json"));
            requestMessage.Headers.UserAgent.Add(new ProductInfoHeaderValue("PostmanRuntime","7.28.0"));

            var responseMessage = await this.HttpClient.SendAsync(requestMessage, cancellationToken);

            if (responseMessage.IsSuccessStatusCode == false)
            {
                throw new Exception($"Unable to find release with tag {tag}");
            }

            var content = await responseMessage.Content.ReadAsStringAsync(cancellationToken);

            // Ok so now extract the release id
            var definition = new
                             {
                                 id = 0,
                                 body = String.Empty
                             };

            // Get the import id from the import response
            var responseDto = JsonConvert.DeserializeAnonymousType(content, definition);

            return (responseDto.id.ToString(), responseDto.body);

        }
        
        public async Task UpdateRelease(String releaseId,
                                        String releaseBody,
                                        CancellationToken cancellationToken)
        {
            String requestUri = $"{this.GithubApiUrl}/releases/{releaseId}";
            HttpRequestMessage requestMessage = new HttpRequestMessage(HttpMethod.Patch, requestUri);
            requestMessage.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/vnd.github.v3+json"));
            requestMessage.Headers.UserAgent.Add(new ProductInfoHeaderValue("PostmanRuntime", "7.28.0"));
            requestMessage.Headers.Authorization = new AuthenticationHeaderValue("Bearer", this.Token);

            // Build the request object
            var dto = new {body = releaseBody};
            requestMessage.Content = new StringContent(JsonConvert.SerializeObject(dto));

            var responseMessage = await this.HttpClient.SendAsync(requestMessage, cancellationToken);

            if (responseMessage.IsSuccessStatusCode == false)
            {
                throw new Exception($"Unable to update release Id {releaseId} with body {releaseBody}, Http Status");
            }
        }
    }
}
