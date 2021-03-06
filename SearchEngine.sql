USE [master]
GO
/****** Object:  Database [SearchEngine]    Script Date: 6/20/2018 6:25:41 PM ******/
CREATE DATABASE [SearchEngine]
GO
ALTER DATABASE [SearchEngine] SET COMPATIBILITY_LEVEL = 130
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [SearchEngine].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [SearchEngine] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [SearchEngine] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [SearchEngine] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [SearchEngine] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [SearchEngine] SET ARITHABORT OFF 
GO
ALTER DATABASE [SearchEngine] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [SearchEngine] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [SearchEngine] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [SearchEngine] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [SearchEngine] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [SearchEngine] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [SearchEngine] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [SearchEngine] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [SearchEngine] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [SearchEngine] SET  ENABLE_BROKER 
GO
ALTER DATABASE [SearchEngine] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [SearchEngine] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [SearchEngine] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [SearchEngine] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [SearchEngine] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [SearchEngine] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [SearchEngine] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [SearchEngine] SET RECOVERY FULL 
GO
ALTER DATABASE [SearchEngine] SET  MULTI_USER 
GO
ALTER DATABASE [SearchEngine] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [SearchEngine] SET DB_CHAINING OFF 
GO
ALTER DATABASE [SearchEngine] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [SearchEngine] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [SearchEngine] SET DELAYED_DURABILITY = DISABLED 
GO
EXEC sys.sp_db_vardecimal_storage_format N'SearchEngine', N'ON'
GO
ALTER DATABASE [SearchEngine] SET QUERY_STORE = OFF
GO
USE [SearchEngine]
GO
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = PRIMARY;
GO
USE [SearchEngine]
GO
/****** Object:  Table [dbo].[Links]    Script Date: 6/20/2018 6:25:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Links](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[FromId] [int] NULL,
	[ToID] [int] NULL,
	[LinkText] [varchar](1000) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PageRank]    Script Date: 6/20/2018 6:25:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PageRank](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[URLId] [int] NULL,
	[Score] [float] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[URLList]    Script Date: 6/20/2018 6:25:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[URLList](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[URL] [varchar](5000) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[WordList]    Script Date: 6/20/2018 6:25:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WordList](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Words] [varchar](100) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[WordLocation]    Script Date: 6/20/2018 6:25:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WordLocation](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[URLId] [int] NULL,
	[WordId] [int] NULL,
	[Location] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[isURLTraversed]    Script Date: 6/20/2018 6:25:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[isURLTraversed]
@url varchar(1000)	
,@isTraversed int OUTPUT
AS
BEGIN

	DECLARE @urlId int = -1
	,@toId int
	
	SELECT @urlId = Id FROM dbo.URLList WHERE url = @url

	IF(@urlId != -1)
	BEGIN
		IF EXISTS (Select * FROM [dbo].[WordLocation] WHERE urlid = @urlId)
		BEGIN
			select @isTraversed = 1
		END
	END
	
	SET @isTraversed =  0
END
GO
/****** Object:  StoredProcedure [dbo].[uspAddURL]    Script Date: 6/20/2018 6:25:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[uspAddURL]
@url varchar(1000)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM dbo.URLList WHERE url = @url)
	BEGIN 
		INSERT INTO dbo.URLList (URL) VALUES (@url)
	END
END
	
GO
/****** Object:  StoredProcedure [dbo].[uspGetURLId]    Script Date: 6/20/2018 6:25:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[uspGetURLId]
@url varchar(1000)	
,@urlId int OUTPUT
AS
BEGIN

	SELECT @urlId = Id FROM dbo.URLList WHERE url = @url

END
GO
/****** Object:  StoredProcedure [dbo].[uspGetWordId]    Script Date: 6/20/2018 6:25:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[uspGetWordId]
@word varchar(1000)	
,@wordId int OUTPUT
AS
BEGIN

	SELECT @wordId = Id FROM [dbo].[WordList] WHERE words = @word

END
GO
/****** Object:  StoredProcedure [dbo].[uspInsertLinks]    Script Date: 6/20/2018 6:25:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[uspInsertLinks]
@urlFrom varchar(1000)
,@urlTo varchar(1000)
,@linkText varchar(1000)
AS
BEGIN

	DECLARE @fromId int
	,@toId int

	SELECT @fromId = ID
	FROM dbo.URLlist
	WHERE url = @urlFrom
	
	SELECT @toId = ID
	FROM dbo.URLlist
	WHERE url = @urlTo

	INSERT INTO dbo.Links (FromID,ToId,LinkText)
	VALUES (@fromId,@toId,@linkText)

	
END
GO
/****** Object:  StoredProcedure [dbo].[uspInsertWord]    Script Date: 6/20/2018 6:25:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[uspInsertWord]
@url varchar(1000)
,@word varchar(1000)	
,@location int
AS
BEGIN
	DECLARE @wordId int = -1
	,@urlID int

	SELECT @urlID = Id FROM dbo.URLList WHERE [URL] = @url

	SELECT @wordId = Id FROM [dbo].[WordList] WHERE words = @word

	if(@wordId = -1)
	BEGIN
		INSERT INTO [dbo].[WordList](Words) VALUES (@word)
		SELECT @wordId = Id FROM [dbo].[WordList] WHERE words = @word
	END

	IF NOT EXISTS (SELECT 1 FROM [dbo].[WordLocation] WHERE wordid = @wordId AND urlid = @urlID AND location = @location)
	BEGIN
		INSERT INTO [dbo].[WordLocation]([URLId],[WordId],[Location]) VALUES (@urlID,@wordId,@location)
	END

	

END
GO
USE [master]
GO
ALTER DATABASE [SearchEngine] SET  READ_WRITE 
GO
