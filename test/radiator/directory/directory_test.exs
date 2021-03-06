defmodule Radiator.DirectoryTest do
  use Radiator.DataCase

  alias Radiator.Directory
  alias Directory.Editor

  import Radiator.Factory

  describe "podcasts" do
    alias Radiator.Directory.Podcast

    test "list_podcasts/0 returns all podcasts" do
      podcast = insert(:podcast)
      assert Directory.list_podcasts() |> Repo.preload(:network) == [podcast]
    end

    test "get_podcast!/1 returns the podcast with given id" do
      podcast = insert(:podcast)
      assert Directory.get_podcast!(podcast.id) |> Repo.preload(:network) == podcast
    end

    test "get_podcast_by_slug/1 returns the podcast with given slug" do
      podcast = insert(:podcast, slug: "podcast-foo-bar-baz")
      assert Directory.get_podcast_by_slug(podcast.slug) |> Repo.preload(:network) == podcast
    end

    test "create_podcast/1 with valid data creates a podcast" do
      network = insert(:network)

      assert {:ok, %Podcast{} = podcast} =
               Editor.Manager.create_podcast(network, %{title: "some title"})

      assert podcast.title == "some title"
    end

    test "create_podcast/1 with invalid data returns error changeset" do
      network = insert(:network)
      assert {:error, %Ecto.Changeset{}} = Editor.Manager.create_podcast(network, %{title: nil})
    end

    test "update_podcast/2 with valid data updates the podcast" do
      podcast = insert(:podcast)

      assert {:ok, %Podcast{} = podcast} =
               Editor.Manager.update_podcast(podcast, %{subtitle: "some updated subtitle"})

      assert podcast.subtitle == "some updated subtitle"
    end

    test "update_podcast/2 doesn't generate slug when published_at is not set" do
      podcast = insert(:podcast)

      {:ok, updated_podcast} =
        Editor.Manager.update_podcast(podcast, %{title: "some updated podcast title"})

      assert updated_podcast.slug == nil

      {:ok, published_podcast} =
        Editor.Manager.update_podcast(updated_podcast, %{published_at: DateTime.utc_now()})

      assert String.length(published_podcast.slug) > 0
    end

    test "update_podcast/2 with invalid data returns error changeset" do
      podcast = insert(:podcast)

      assert {:error, %Ecto.Changeset{}} = Editor.Manager.update_podcast(podcast, %{title: nil})

      assert podcast == Directory.get_podcast!(podcast.id) |> Repo.preload(:network)
    end

    test "delete_podcast/1 deletes the podcast" do
      podcast = insert(:podcast)
      assert {:ok, %Podcast{}} = Editor.Manager.delete_podcast(podcast)
      assert_raise Ecto.NoResultsError, fn -> Directory.get_podcast!(podcast.id) end
    end

    test "change_podcast/1 returns a podcast changeset" do
      podcast = insert(:podcast)
      assert %Ecto.Changeset{} = Editor.Manager.change_podcast(podcast)
    end

    test "publish_podcast/1 sets a published_at date" do
      podcast = insert(:podcast, published_at: nil)

      assert {:ok, %Podcast{} = published_podcast} = Editor.Manager.publish_podcast(podcast)
      assert published_podcast.published_at != nil
      assert :gt == DateTime.compare(DateTime.utc_now(), published_podcast.published_at)
    end

    test "publish_podcast/1 generates a slug from title" do
      podcast = insert(:podcast, published_at: nil)

      {:ok, published_podcast} = Editor.Manager.publish_podcast(podcast)
      assert is_binary(published_podcast.slug)
      assert String.length(published_podcast.slug) > 0
    end

    test "publish_podcast/1 generates sequential slugs" do
      {:ok, existing_podcast} =
        insert(:podcast)
        |> Editor.Manager.publish_podcast()

      {:ok, published_podcast1} =
        insert(:podcast, title: existing_podcast.title)
        |> Editor.Manager.publish_podcast()

      assert published_podcast1.slug == "#{existing_podcast.slug}-1"

      {:ok, published_podcast2} =
        insert(:podcast, title: existing_podcast.title)
        |> Editor.Manager.publish_podcast()

      assert published_podcast2.slug == "#{existing_podcast.slug}-2"

      {:ok, published_podcast3} =
        insert(:podcast, title: existing_podcast.title)
        |> Editor.Manager.publish_podcast()

      assert published_podcast3.slug == "#{existing_podcast.slug}-3"
    end

    test "publish_podcast/1 with invalid data returns error changeset" do
      podcast = insert(:podcast)

      assert {:error, %Ecto.Changeset{}} =
               Editor.Manager.publish_podcast(%{podcast | :title => nil})

      assert %Podcast{published_at: nil} = Directory.get_podcast!(podcast.id)
    end

    test "depublish_podcast/1 removes a podcasts published_at date" do
      podcast = insert(:podcast, published_at: DateTime.utc_now())

      assert {:ok, %Podcast{published_at: nil}} = Editor.Manager.depublish_podcast(podcast)
    end

    test "depublish_podcast/1 with invalid data returns error changeset" do
      podcast = insert(:podcast, published_at: DateTime.utc_now())
      published_at = podcast.published_at

      assert {:error, %Ecto.Changeset{}} =
               Editor.Manager.depublish_podcast(%{podcast | :title => nil})

      assert %Podcast{published_at: ^published_at} = Directory.get_podcast!(podcast.id)
    end
  end

  describe "episodes" do
    alias Radiator.Directory.Episode

    @valid_attrs %{title: "some title"}
    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}

    test "list_episodes/0 returns all episodes" do
      episode = insert(:episode)
      assert Directory.list_episodes() |> Repo.preload(podcast: :network) == [episode]
    end

    test "get_episode!/1 returns the episode with given id" do
      episode = insert(:episode)
      assert Directory.get_episode!(episode.id) |> Repo.preload(podcast: :network) == episode
    end

    test "get_episode_by_slug/1 returns the episode with given slug" do
      episode = insert(:episode, slug: "episode-foo-bar-baz")

      assert Directory.get_episode_by_slug(episode.slug) |> Repo.preload(podcast: :network) ==
               episode
    end

    test "create_episode/1 with valid data creates an episode" do
      assert {:ok, %Episode{} = episode} =
               Editor.Manager.create_episode(insert(:podcast), @valid_attrs)

      assert episode.title == "some title"
    end

    test "create_episode/1 with invalid data returns error changeset" do
      podcast = insert(:podcast)

      assert {:error, %Ecto.Changeset{}} = Editor.Manager.create_episode(podcast, @invalid_attrs)
    end

    test "update_episode/2 with valid data updates the episode" do
      episode = insert(:episode)
      assert {:ok, %Episode{} = episode} = Editor.Manager.update_episode(episode, @update_attrs)
      assert episode.title == "some updated title"
    end

    test "update_episode/2 doesn't generate slug when published_at is not set" do
      episode = insert(:episode)

      {:ok, updated_episode} =
        Editor.Manager.update_episode(episode, %{title: "some updated episode title"})

      assert updated_episode.slug == nil

      {:ok, published_episode} =
        Editor.Manager.update_episode(updated_episode, %{published_at: DateTime.utc_now()})

      assert String.length(published_episode.slug) > 0
    end

    test "update_episode/2 with invalid data returns error changeset" do
      episode = insert(:episode)
      assert {:error, %Ecto.Changeset{}} = Editor.Manager.update_episode(episode, @invalid_attrs)
      assert episode == Directory.get_episode!(episode.id) |> Repo.preload(podcast: :network)
    end

    test "delete_episode/1 deletes the episode" do
      episode = insert(:episode)
      assert {:ok, %Episode{}} = Editor.Manager.delete_episode(episode)
      assert_raise Ecto.NoResultsError, fn -> Directory.get_episode!(episode.id) end
    end

    test "change_episode/1 returns an episode changeset" do
      episode = insert(:episode)
      assert %Ecto.Changeset{} = Editor.Manager.change_episode(episode)
    end

    test "publish_episode/1 sets a published_at date" do
      episode = insert(:episode, published_at: nil)

      assert {:ok, %Episode{} = published_episode} = Editor.Manager.publish_episode(episode)
      assert published_episode.published_at != nil
      assert :gt == DateTime.compare(DateTime.utc_now(), published_episode.published_at)
    end

    test "publish_episode/1 generates a slug from title" do
      episode = insert(:episode, published_at: nil)

      {:ok, published_episode} = Editor.Manager.publish_episode(episode)
      assert is_binary(published_episode.slug)
      assert String.length(published_episode.slug) > 0
    end

    test "publish_episode/1 generates sequential slugs" do
      {:ok, existing_episode} =
        insert(:episode)
        |> Editor.Manager.publish_episode()

      {:ok, published_episode1} =
        insert(:episode, title: existing_episode.title)
        |> Editor.Manager.publish_episode()

      assert published_episode1.slug == "#{existing_episode.slug}-1"

      {:ok, published_episode2} =
        insert(:episode, title: existing_episode.title)
        |> Editor.Manager.publish_episode()

      assert published_episode2.slug == "#{existing_episode.slug}-2"

      {:ok, published_episode3} =
        insert(:episode, title: existing_episode.title)
        |> Editor.Manager.publish_episode()

      assert published_episode3.slug == "#{existing_episode.slug}-3"
    end

    test "publish_episode/1 with invalid data returns error changeset" do
      episode = insert(:episode)

      assert {:error, %Ecto.Changeset{}} =
               Editor.Manager.publish_episode(%{episode | :title => nil})

      assert %Episode{published_at: nil} = Directory.get_episode!(episode.id)
    end

    test "depublish_episode/1 removes an episodes published_at date" do
      episode = insert(:episode, published_at: DateTime.utc_now())

      assert {:ok, %Episode{published_at: nil}} = Editor.Manager.depublish_episode(episode)
    end

    test "depublish_episode/1 with invalid data returns error changeset" do
      episode = insert(:episode, published_at: DateTime.utc_now())
      published_at = episode.published_at

      assert {:error, %Ecto.Changeset{}} =
               Editor.Manager.depublish_episode(%{episode | :title => nil})

      assert %Episode{published_at: ^published_at} = Directory.get_episode!(episode.id)
    end
  end

  describe "networks" do
    alias Radiator.Directory.Network

    @valid_attrs %{title: "some title"}
    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}

    def network_fixture(attrs \\ %{}) do
      testuser = Radiator.TestEntries.user()

      {:ok, %{network: network}} =
        Editor.Owner.create_network(testuser, Enum.into(attrs, @valid_attrs))

      network
    end

    test "list_networks/0 returns all networks" do
      network = network_fixture()
      assert Directory.list_networks() == [network]
    end

    test "get_network!/1 returns the network with given id" do
      network = network_fixture()
      assert Directory.get_network!(network.id) == network
    end

    test "get_network_by_slug/1 returns the network with given slug" do
      network = insert(:network, slug: "network-foo-bar-baz")
      assert Directory.get_network_by_slug(network.slug) == network
    end

    test "create_network/1 with valid data creates a network" do
      testuser = Radiator.TestEntries.user()

      assert {:ok, %{network: %Network{} = network}} =
               Editor.Owner.create_network(testuser, @valid_attrs)

      assert network.title == "some title"
    end

    test "create_network/1 generates a slug from the new networks title" do
      testuser = Radiator.TestEntries.user()

      assert {:ok, %{network: %Network{} = network}} =
               Editor.Owner.create_network(testuser, %{title: "Network Slug Test"})

      assert network.slug == "network-slug-test"
    end

    test "create_network/1 with invalid data returns error changeset" do
      testuser = Radiator.TestEntries.user()

      assert {:error, :network, %Ecto.Changeset{}, _} =
               Editor.Owner.create_network(testuser, @invalid_attrs)
    end

    test "update_network/2 with valid data updates the network" do
      network = network_fixture()
      assert {:ok, %Network{} = network} = Editor.Owner.update_network(network, @update_attrs)
      assert network.title == "some updated title"
    end

    test "update_network/2 with invalid data returns error changeset" do
      network = network_fixture()
      assert {:error, %Ecto.Changeset{}} = Editor.Owner.update_network(network, @invalid_attrs)
      assert network == Directory.get_network!(network.id)
    end

    test "delete_network/1 deletes the network" do
      network = network_fixture()
      assert {:ok, %Network{}} = Editor.Owner.delete_network(network)
      assert_raise Ecto.NoResultsError, fn -> Directory.get_network!(network.id) end
    end
  end

  describe "audio files" do
    alias Radiator.Media.AudioFile

    test "get_audio_file/1 returns audio file" do
      episode = insert(:published_episode)
      audio = create_episode_audio(episode)

      assert {:ok, %AudioFile{file: %{file_name: "pling.mp3"}}} =
               Directory.get_audio_file(audio.id)
    end

    test "get_audio_file/1 errors when accessing unpublished audio file" do
      episode = insert(:unpublished_episode)
      audio = create_episode_audio(episode)

      assert {:error, :unpublished} = Directory.get_audio_file(audio.id)
    end

    test "get_audio_file/1 errors when accessing nonexisting audio file" do
      assert {:error, :not_found} = Directory.get_audio_file(1)
    end
  end

  def create_episode_audio(episode) do
    upload = %Plug.Upload{
      path: "test/fixtures/pling.mp3",
      filename: "pling.mp3"
    }

    {:ok, audio, _} = Radiator.Media.AudioFileUpload.upload(upload, episode)

    audio
  end
end
