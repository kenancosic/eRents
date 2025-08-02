# Simple Dockerfile for eRents WebApi
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["eRents.WebApi/eRents.WebApi.csproj", "eRents.WebApi/"]
COPY ["eRents.Features/eRents.Features.csproj", "eRents.Features/"]
COPY ["eRents.Domain/eRents.Domain.csproj", "eRents.Domain/"]
COPY ["eRents.Shared/eRents.Shared.csproj", "eRents.Shared/"]
RUN dotnet restore "eRents.WebApi/eRents.WebApi.csproj"
COPY . .
WORKDIR "/src/eRents.WebApi"
RUN dotnet build "eRents.WebApi.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "eRents.WebApi.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "eRents.WebApi.dll"]