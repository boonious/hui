defmodule HuiUpdateLiveTest do
  use ExUnit.Case, async: true
  import TestHelpers

  alias Hui.Query

  describe "update (live)" do
    @describetag live: false

    test "should post a single doc (Map)" do
      url = %Hui.URL{
        url: "http://localhost:8983/solr/gettingstarted",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      doc_map = %{
        "actor_ss" => ["Bette Davis", "Anne Baxter", "George Sanders"],
        "desc" =>
          "An ingenue insinuates herself into the company of an established but aging stage actress and her circle of theater friends.",
        "directed_by" => ["Joseph L. Mankiewicz"],
        "genre" => ["Drama"],
        "id" => "tt0042192",
        "initial_release_date" => "1950-10-27",
        "name" => "All About Eve"
      }

      delete_verify_doc_deletion(
        url,
        %Query.Update{delete_id: "tt0042192", commit: true},
        "tt0042192"
      )

      Hui.update(url, doc_map)
      verify_docs_exist(:default, ["tt0042192"])
    end

    test "should post multiple docs (Map)" do
      url = %Hui.URL{
        url: "http://localhost:8983/solr/gettingstarted",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      doc_map1 = %{
        "actor_ss" => ["Ralph Fiennes", "F. Murray Abraham", "Mathieu Amalric"],
        "desc" =>
          "The adventures of Gustave H, a legendary concierge at a famous hotel from the fictional Republic of Zubrowka between the first and second World Wars, and Zero Moustafa, the lobby boy who becomes his most trusted friend.",
        "directed_by" => ["Wes Anderson"],
        "genre" => ["Adventure", "Comedy", "Drama"],
        "id" => "tt2278388",
        "initial_release_date" => "2014-03-09",
        "name" => "The Grand Budapest Hotel"
      }

      doc_map2 = %{
        "actor_ss" => ["Leonardo DiCaprio", "Emily Mortimer", "Mark Ruffalo"],
        "desc" =>
          "In 1954, a U.S. Marshal investigates the disappearance of a murderer, who escaped from a hospital for the criminally insane.",
        "directed_by" => ["Martin Scorsese"],
        "genre" => ["Mystery", "Thriller"],
        "id" => "tt1130884",
        "initial_release_date" => "2010-06-10",
        "name" => "Shutter Island"
      }

      delete_verify_doc_deletion(
        url,
        %Query.Update{delete_id: ["tt2278388", "tt1130884"], commit: true},
        ["tt2278388", "tt1130884"]
      )

      Hui.update(url, [doc_map1, doc_map2])
      verify_docs_exist(:default, ["tt2278388", "tt1130884"])
    end

    test "should post binary data" do
      url = %Hui.URL{
        url: "http://localhost:8983/solr/gettingstarted",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      delete_verify_doc_deletion(url, File.read!("./test/data/delete_doc1.json"), "9780141981727")

      update_doc = File.read!("./test/data/update_doc1.json")
      Hui.update(url, update_doc)
      url = %Hui.URL{url | headers: [{"Content-type", "application/xml"}]}
      Hui.update(url, "<commit/>")

      verify_docs_exist(:default, ["9780141981727"])
    end

    test "should post binary data with commitWithin and overwrite" do
      url = %Hui.URL{
        url: "http://localhost:8983/solr/gettingstarted",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      delete_verify_doc_deletion(url, "{\"delete\":{\"id\":\"tt0062622\"}}", "tt0062622")

      Hui.update(url, File.read!("./test/data/update_doc7.json"))
      :timer.sleep(100)

      verify_docs_exist(:default, ["tt0062622"])
    end

    test "shoud delete documents by ID" do
      url = %Hui.URL{
        url: "http://localhost:8983/solr/gettingstarted",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      doc_map1 = %{
        "actor_ss" => ["Toni Servillo", "Carlo Verdone", "Sabrina Ferilli"],
        "desc" =>
          "Jep Gambardella has seduced his way through the lavish nightlife of Rome for decades, but after his 65th birthday and a shock from the past, Jep looks past the nightclubs and parties to find a timeless landscape of absurd, exquisite beauty.",
        "directed_by" => ["Paolo Sorrentino"],
        "genre" => ["Drama"],
        "id" => "tt2358891",
        "initial_release_date" => "2013-09-06",
        "name" => "La grande bellezza"
      }

      doc_map2 = %{
        "actor_ss" => ["Jean-Louis Trintignant", "Emmanuelle Riva", "Isabelle Huppert"],
        "desc" =>
          "Georges and Anne are an octogenarian couple. They are cultivated, retired music teachers. Their daughter, also a musician, lives in Britain with her family. One day, Anne has a stroke, and the couple's bond of love is severely tested.",
        "directed_by" => ["Michael Haneke"],
        "genre" => ["Drama", "Romance"],
        "id" => "tt1602620",
        "initial_release_date" => "2012-11-16",
        "name" => "Amour"
      }

      Hui.update(url, [doc_map1, doc_map2])
      verify_docs_exist(:default, ["tt2358891", "tt1602620"])

      Hui.delete(url, ["tt2358891", "tt1602620"])
      verify_docs_missing(:default, ["tt2358891", "tt1602620"])
    end

    test "shoud delete documents by query" do
      url = %Hui.URL{
        url: "http://localhost:8983/solr/gettingstarted",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      doc_map1 = %{
        "actor_ss" => ["Guy Pearce", "Carrie-Anne Moss"],
        "desc" => "A man with short-term memory loss attempts to track down his wife's murderer.",
        "directed_by" => ["Christopher Nolan"],
        "genre" => ["Mystery", "Thriller"],
        "id" => "tt0209144",
        "initial_release_date" => "2000-10-20",
        "name" => "Memento"
      }

      Hui.update(url, doc_map1)
      verify_docs_exist(:default, ["tt0209144"])

      Hui.delete_by_query(url, "name:Memento")
      verify_docs_missing(:default, ["tt0209144"])
    end
  end
end
