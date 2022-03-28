namespace PowerBIReleaseTool.Services
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Net.Http;
    using System.Net.Http.Headers;
    using System.Threading;
    using System.Threading.Tasks;
    using Newtonsoft.Json;
    using Vme.Configuration;

    public class GitHubService : IGitHubService
    {
        private readonly String Token;

        private readonly HttpClient HttpClient;
        public GitHubService()
        {
            this.GithubApiUrl = ConfigurationReader.GetValue("GitHubApiUrl");
            this.Token = ConfigurationReader.GetValue("GithubAccessToken");
            this.HttpClient = new HttpClient();
        }
        
        public async Task<GitHubReleaseDTO> GetRelease(String tag, CancellationToken cancellationToken)
        {
            String requestUri = $"{this.GithubApiUrl}/releases/tags/{tag}";
            HttpRequestMessage requestMessage = new HttpRequestMessage(HttpMethod.Get, requestUri);
            requestMessage.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/vnd.github.v3+json"));
            requestMessage.Headers.UserAgent.Add(new ProductInfoHeaderValue("PostmanRuntime", "7.28.0"));

            var responseMessage = await this.HttpClient.SendAsync(requestMessage, cancellationToken);

            if (responseMessage.IsSuccessStatusCode == false)
            {
                throw new Exception($"Unable to find release with tag {tag}");
            }

            var content = await responseMessage.Content.ReadAsStringAsync(cancellationToken);

            // Get the import id from the import response
            GitHubReleaseDTO responseDto = JsonConvert.DeserializeObject<GitHubReleaseDTO>(content);

            return responseDto;
        }

        public async Task<String> GetReleaseAsset(Int32 assetId,
                                                  String assetName,
                                                  String outputPath,
                                                  CancellationToken cancellationToken)
        {
            String requestUri = $"{this.GithubApiUrl}/releases/assets/{assetId}";
            HttpRequestMessage requestMessage = new HttpRequestMessage(HttpMethod.Get, requestUri);
            requestMessage.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/octet-stream"));
            requestMessage.Headers.UserAgent.Add(new ProductInfoHeaderValue("PostmanRuntime", "7.28.0"));

            var responseMessage = await this.HttpClient.SendAsync(requestMessage, cancellationToken);

            if (responseMessage.IsSuccessStatusCode == false)
            {
                throw new Exception($"Unable to find release asset with id {assetId}");
            }

            var content = await responseMessage.Content.ReadAsStreamAsync(cancellationToken);

            using (var fileStream = File.Create($"{outputPath}\\{assetName}"))
            {
                content.Seek(0, SeekOrigin.Begin);
                content.CopyTo(fileStream);
            }

            return $"{outputPath}\\{assetName}";
        }

        public async Task<List<GitHubReleaseDTO>> GetReleases(CancellationToken cancellationToken)
        {
            String requestUri = $"{this.GithubApiUrl}/releases";
            HttpRequestMessage requestMessage = new HttpRequestMessage(HttpMethod.Get, requestUri);
            requestMessage.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/vnd.github.v3+json"));
            requestMessage.Headers.UserAgent.Add(new ProductInfoHeaderValue("PostmanRuntime", "7.28.0"));

            var responseMessage = await this.HttpClient.SendAsync(requestMessage, cancellationToken);

            if (responseMessage.IsSuccessStatusCode == false)
            {
                throw new Exception($"Unable to find release list. Http Status: [{responseMessage.StatusCode}] Content: [{await responseMessage.Content.ReadAsStringAsync(cancellationToken)}]");
            }

            var content = await responseMessage.Content.ReadAsStringAsync(cancellationToken);

            // Get the import id from the import response
            var responseDto = JsonConvert.DeserializeObject<List<GitHubReleaseDTO>>(content);

            responseDto = responseDto.Where(r => r.Assets.Count > 0).ToList();

            return responseDto;
        }

        public String GithubApiUrl { get; }

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
            var dto = new { body = releaseBody };
            requestMessage.Content = new StringContent(JsonConvert.SerializeObject(dto));

            var responseMessage = await this.HttpClient.SendAsync(requestMessage, cancellationToken);

            if (responseMessage.IsSuccessStatusCode == false)
            {
                throw new Exception($"Unable to update release Id {releaseId} with body {releaseBody}, Http Status");
            }
        }
    }
}