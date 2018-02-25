RSpec.describe "assets config", "types" do
  let :app do
    Pakyow.app(:test)
  end

  let :config do
    app.config.assets
  end

  it "defines types for av" do
    expect(config.types[:av]).to eq(%w(.webm .snd .au .aiff .mp3 .mp2 .m2a .m3a .ogx .gg .oga .midi .mid .avi .wav .wave .mp4 .m4v .acc .m4a .flac))
  end

  it "defines types for data" do
    expect(config.types[:data]).to eq(%w(.json .xml .yml .yaml))
  end

  it "defines types for fonts" do
    expect(config.types[:fonts]).to eq(%w(.eot .otf .ttf .woff .woff2))
  end

  it "defines types for images" do
    expect(config.types[:images]).to eq(%w(.ico .bmp .gif .webp .png .jpg .jpeg .tiff .tif .svg))
  end

  it "defines types for scripts" do
    expect(config.types[:scripts]).to eq(%w(.js .es6 .eco .ejs))
  end

  it "defines types for styles" do
    expect(config.types[:styles]).to eq(%w(.css .sass .scss))
  end
end
